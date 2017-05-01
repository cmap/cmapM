function ds = infer_tool(varargin)
% INFER_TOOL Apply inference model.
%   INFER_TOOL('res', 'test.gct', 'model', 'mlr12k.mat')
% See also TRAINMLR_TOOL

toolName = mfilename;
% default output folder is the submit path
dflt_out=get_lsf_submit_dir;

% sin keyfields
validreg = {'pinv_int','mldivide', 'pls'};
valid_xform = {'none', 'log2', 'abs', 'pow2' ,'zscore' };
PRECISION = 4;

pnames = {'res', 'out', 'regtype',...
	  'scale', 'xform',...
      'model', 'precision', 'gengd',...
      'minval','maxval', 'outfmt'};
dflts =  {'', dflt_out,  'pinv_int',...
	      false, 'none',...
          '', PRECISION, true,...
          0, 15, 'gct'};

arg = parse_args(pnames, dflts, varargin{:});
print_args(toolName, 1, arg);

% check if valid reg type
if ~isvalidstr(arg.regtype, validreg)
    error('Invalid regtype: %s\n', arg.regtype);
end

% read gct
if isstruct(arg.res)
    ds = arg.res;
    arg.res = ds.src;
elseif isfileexist(arg.res)
  if ~isempty(regexp(arg.res, '\.gctx$', 'once'))
      ds = parse_gctx(arg.res);
  else
      ds = parse_gct(arg.res);
  end  
else
  error([toolName,':FileNotFound'], 'res: %s not found', arg.res)
end
[~, numSamples] = size(ds.mat);
% apply transformation
if ~isequal(arg.xform,'none')
    ds.mat = do_xform(ds.mat,arg.xform, valid_xform, true);    
end

%read model
if isstruct(arg.model)
    model=arg.model;
    arg.model='unnamed';
elseif isfileexist(arg.model)
  [p,f,e] = fileparts(arg.model);
  switch(e)
      case '.mat'
          load(arg.model);
      otherwise
          error('Invalid model extension: %s',arg.model)          
  end
else
  error([toolName,':FileNotFound'], 'model: %s not found', arg.model)
end
% infer spaces
% landmarks
landmarkspace = model.cn;
% dependent features
depspace = model.rn;

% landmark indices
[cmn_lm, landmarkidx] = intersect_ord(ds.rid, landmarkspace);
% all landmarks should be present
if ~isequal(length(cmn_lm), length(landmarkspace))
    d=setdiff(landmarkspace, cmn_lm);
    disp(d);
    error('%d/%d landmarks not found in test set!',length(d), length(landmarkspace));
end

nlm = length(landmarkspace);
ndep = length(depspace);

%reorder features [lm;dep]
ds.rid = [landmarkspace; depspace];
% set ds.mat(1:nlm,:) = landmarks in model order
ds.mat = [ds.mat(landmarkidx,:); zeros(ndep, numSamples)];
numFeatures = length(ds.rid);

%row desc
nh = length(ds.rhd);
newkeys = { 'pr_gene_symbol';'pr_gene_title';'pr_gene_id';'pr_is_lmark';'pr_model_id'};
keystoadd = setdiff( newkeys, ds.rhd);
ntoadd = length(keystoadd);
ds.rhd = [ds.rhd; keystoadd];
ds.rdict = list2dict(ds.rhd);
gd = cell(numFeatures, nh+ntoadd);
gd(:) = {-666};
if nh
    gd(1:nlm, 1:nh) = ds.rdesc(landmarkidx, :);
end
[gsym, desc, ezid] = ps2genesym(ds.rid, varargin{:});
for ii=1:length(newkeys)
    switch(newkeys{ii})
        case 'pr_gene_symbol'
            gd(:, ds.rdict('pr_gene_symbol')) = gsym;
        case 'pr_gene_id'
            gd(:, ds.rdict('pr_gene_id')) = ezid;
        case 'pr_gene_title'
            gd(:, ds.rdict('pr_gene_title')) = desc;
        case 'pr_is_lmark'
            gd(1:nlm, ds.rdict('pr_is_lmark')) = {'Y'};
            gd(nlm+(1:ndep), ds.rdict('pr_is_lmark')) = {'N'};
        case 'pr_model_id'
            [~, modelname] = fileparts(arg.model);
            gd(1:nlm, ds.rdict('pr_model_id')) = {-666};
            gd(nlm+(1:ndep), ds.rdict('pr_model_id')) = {modelname};
    end
end
ds.rdesc = gd;

% % apply scaling if used for training
% % scale landmarks to [-1,+1]
% if model.arg.scale
%     fprintf ('Rescaling predictors to [-1 +1]\n')
%     scx =  scaleinput(ds.mat(landmarkidx,:)', model.scfactor);
%     ds.mat(landmarkidx,:) = scx';
% end

%% regression
% test model
fprintf ('Applying regression model [%s:%s]. Using %d landmarks, %d dependents, %d samples\n', ...
         model.arg.regtype, modelname, nlm, ndep, numSamples);
     switch (model.arg.regtype)
         case 'pinv_int'
             % [D x S] = [D x L+1] * [L+1 x S]
             Y = model.wt * [ones(1,numSamples); ds.mat(1:nlm,:)];
         otherwise
             error ('Unknown model type: %s', model.arg.regtype)
             
     end
%threshold values
Y = min(max(Y, arg.minval), arg.maxval);

% update expression matrix
ds.mat(nlm+(1:ndep), :) = Y;

%% analysis ouput folders
if nargout==0
    % extract prefix from testing set
    [~, tstlabel] = fileparts(arg.res);
    tstlabel = strip_dimlabel(tstlabel);
    [~, trnlabel] = fileparts(model.arg.res);
    [~, lmlabel] = fileparts(model.arg.grp_landmark);
    
    if isdirexist(arg.out)
        wkdir = arg.out;
        inf_file = fullfile(wkdir, sprintf('%s_INF.gct', tstlabel));
    else
        p = fileparts(arg.out);
        wkdir = mkworkfolder(p, 'infer', 'forcesuffix', false, 'overwrite', true);
        inf_file = arg.out;
    end
    
    fprintf ('Saving analysis to %s\n',wkdir);
    
    % save parameters
    fid = fopen(fullfile(wkdir, sprintf('%s_params.txt',toolName)), 'wt');
    print_args( toolName, fid, arg);
    fclose (fid);
    
    % inferred results
    switch(lower(arg.outfmt))
        case 'gct'
            mkgct( inf_file, ds, 'precision', arg.precision);
        case 'gctx'
            h5_file = strrep(inf_file,'.gct','.gctx');
            mkgctx(h5_file, ds);
    end
end