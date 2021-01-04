function model = trainmlr_tool(varargin)
% TRAINMLR_TOOL - Train MLR model for L1000 data
% TRAINMLR_TOOL('res', 'train.gct', 'grp_landmark', 'lm.grp')

toolName = mfilename;
% default output folder is the submit path
dflt_out=get_lsf_submit_dir;

% sin keyfields
kf = {'SAMPLE_NAME','CEL_FILE_NAME'};
dimf = {'Sample','Gene'};
validreg = {'pinv','pinv_int','mldivide', 'pls'};
valid_xform = {'none', 'log2', 'abs', 'pow2' ,'zscore' };
PRECISION = 4;

pnames = {'res', 'sin', 'gin', 'rid', 'cid', ... 
	  'out', 'regtype', 'transpose', 'debug', ...
	  'grp_landmark', 'scale', 'xform', 'precision'};
dflts =  {    '',     '',     '',      '',      '',   ... 
	      dflt_out,  'pinv_int', false,  false, ...
	      '', false, 'none', PRECISION };

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
      ds = parse_gctx(arg.res, 'rid', arg.rid, 'cid', arg.cid);
  else
      ds = parse_gct(arg.res);
  end  
else
  error([toolName,':FileNotFound'], 'res: %s not found', arg.res)
end
[numFeatures, numSamples] = size(ds.mat);        
% apply transformation
if ~isequal(arg.xform,'none')
    ds.mat = do_xform(ds.mat,arg.xform, valid_xform, true);    
end

% landmark genes
if iscell(arg.grp_landmark) || isfileexist(arg.grp_landmark)
  lmspace = parse_grp(arg.grp_landmark);  
  % landmark indices
  [cmn, landmarkidx] = intersect_ord(ds.rid, lmspace);
  nlm=length(lmspace);
  if ~isequal(length(cmn), length(lmspace))
    disp(setdiff(lmspace, cmn));
    error('Some landmarks not found in train set');
  end
  
  % indices of genes to be predicted
  [depspace, dependentidx] = setdiff(ds.rid, lmspace);
  ndep = length(depspace);
  if isempty(dependentidx)
      error('No dependent features to predict!');
  end
else
  error('Landmarks not specified')
end

% if scaling predictors requested
scfactor=[];

%% regression
% train model
fprintf ('Training regression model [%s]:%d landmarks, %d dependents, %d samples\n', ...
         arg.regtype, nlm, ndep, numSamples);
     switch (arg.regtype)
         % [DEFAULT] pseudoinverse with intercept    
         case 'pinv_int'             
             % design matrix [S x L+1]
             X = [ones(numSamples,1), ds.mat(landmarkidx,:)'];
             % [L+1 x D] = [ L+1 X S ] * [S x D]             
             wt = pinv(X) * ds.mat(dependentidx,:)';
             % [S x D] = [S x L+1] * [L+1 x D]
%              trp = X * wt;
         otherwise
             error('Unkown model type: %s', arg.regtype)
     end
     model = struct('wt', wt', 'rn', {ds.rid(dependentidx)},...
         'cn', {ds.rid(landmarkidx)},...
         'arg',arg,'scfactor', scfactor);
%save model as struct (more efficient and better precision)
if isequal(nargout,0)
    %% analysis ouput folders
    wkdir = mkworkfolder(arg.out, toolName);
    fprintf ('Saving analysis to %s\n',wkdir);    
    % save parameters
    fid = fopen(fullfile(wkdir, sprintf('%s_params.txt',toolName)), 'wt');
    print_args( toolName, fid, arg);
    fclose (fid);

    %extract prefix from training set
    [p, trlabel] = fileparts(arg.res);
    [p, lmlabel] = fileparts(arg.grp_landmark);
    modelfile = fullfile(wkdir, sprintf('model_%s_%s_%s.mat', arg.regtype, trlabel, lmlabel));
    fprintf ('Saving model to %s\n', modelfile);
    save(modelfile, 'model');
end
