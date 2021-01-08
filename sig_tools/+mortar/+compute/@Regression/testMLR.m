function ds = testMLR(varargin)

pnames = {'ds', 'model', 'minval', 'maxval', 'xform', 'dep_meta'};
dflts = {'','', 0, 15, 'none', ''};

args = parse_args(pnames, dflts, varargin{:});

if isstruct(args.ds)
    ds = args.ds;
    args.ds = ds.src;
elseif isfileexist(args.ds)
    ds = parse_gctx(args.ds);
else
    error('res: %s not found', args.ds);
end

ds.mat = do_xform(ds.mat, args.xform, 'verbose', true);

if isstruct(args.model)
    model = args.model;
    modelname = 'User Struct';
elseif isfileexist(args.model)
    [~,~,ext] = fileparts(args.model);
    switch ext
        case '.mat'
            load(args.model);
        case '.gct'
            model = parse_gct(args.model);
        case '.gctx'
            model = parse_gctx(args.model);
        otherwise
            error('Invalid model filetype');
    end
    [~, modelname] = fileparts(args.model);
else
    error('Model not specified')
end   

modeltype = ds_get_meta(model, 'column', 'modeltype');
modeltype = modeltype{1};
if isequal(modeltype, 'pinv_int')
    lmspace = model.cid(2:end);
else
    lmspace = model.cid;
end

[~, numSamples] = size(ds.mat);
[cmn, ~, lmidx] = intersect(lmspace, ds.rid, 'stable');
nlm = length(lmspace);
if ~isequal(length(cmn), length(lmspace))
    disp(setdiff(lmspace, cmn));
    error('Some landmarks not found in dataset \n');
end

% dependent gene space
depspace = model.rid;
ndep = length(depspace);

% landmarks not used in the inference; retain in the output
[unusedspace, unused_ridx] = setdiff(ds.rid, union(lmspace, depspace));
unused_mat = ds.mat(unused_ridx, :);
     
%[L x S]
ldmrkmat = ds.mat(lmidx, :);

% unused 

% Use training model to infer  result from input
dbg(1, 'Applying regression model [%s:%s]. Using %d landmarks, %d dependents, %d samples\n', ...
         modeltype, modelname, nlm, ndep, numSamples);

switch (modeltype)
    case 'pinv_int'
        %[D x S] = [D x L+1] * [L+1 x S]
        infdep = model.mat * [ones(1,numSamples); ldmrkmat];         
    case 'pinv'
        %[D x S] = [D x L] * [L x S]
        infdep = model.mat * ldmrkmat;
    otherwise
        error('Unknown model type: %s', modeltype);
end

% threshold inferred values
infdep = clip(infdep, args.minval, args.maxval);
inf_ds = mkgctstruct(infdep, 'rid', depspace, 'cid', ds.cid);
if ~isempty(args.dep_meta)
    inf_ds = annotate_ds(inf_ds, args.dep_meta, 'dim', 'row');
end
% set the pr_is_lmark to 0 explicity for dep genes, overriding metadata
inf_ds = ds_add_meta(inf_ds, 'row', 'pr_is_lmark', {0});
inf_ds = ds_add_meta(inf_ds, 'row', 'pr_is_inf', {1});

lm_ds = ds_slice(ds, 'rid', [lmspace; unusedspace]);
ds = merge_two(lm_ds, inf_ds);

end
