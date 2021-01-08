function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)
res = struct('args', args,...
    'pc_coeff', [],...
    'pc_score', [],...
    'pc_var', [],...
    'pct_explained', [],...
    'col_mean', []);

% load data
if ~isempty(args.rid)
    % custom space
    args.row_space = 'custom';
    rid =  parse_grp(args.rid);
elseif ~strcmpi(args.row_space, 'all')
    % pre-defined row_space
    is_valid_row_space = mortar.common.Spaces.probe_space.isKey(args.row_space);
    assert(is_valid_row_space, 'Invalid row space %s', args.row_space);
    rid = mortar.common.Spaces.probe(args.row_space).asCell;
else
    % default to all
    rid = '';
end

ds = parse_gctx(args.ds,...
               'cid', args.cid,...
               'rid', rid);

% run tsne on the required dimension
[sample_dim_str, sample_dim_val] = get_dim2d(args.sample_dim);

% Apply annotations if provided
if ~isempty(args.ds_meta)
    dbg(1, 'Applying annotations from %s', args.ds_meta);
    ds = annotate_ds(ds, args.ds_meta, 'dim', sample_dim_str);    
end

if isequal(sample_dim_str, 'column')
    dbg(1, '# Using columns as samples and rows as features, transposing input matrix');    
    ds = transpose_gct(ds);
else
    dbg(1, '# Using columns as features and rows as samples');    
end
% PCA , col = variables, rows = observations
[pc_coeff, pc_score, pc_var] = pca(ds.mat);
pct_explained = 100 * pc_var / sum(pc_var);
col_mean = mean(ds.mat);

comp_labels = gen_labels(size(pc_coeff, 2),...
    'prefix', 'PCA', 'zeropad', false);
col_meta = gctmeta(ds, 'column');
row_meta = gctmeta(ds, 'row');

% result datasets
% PCA Coeffecients [P x P], each column is one PC, columns ordered
% according to descending component variance
res.pc_coeff = mkgctstruct(pc_coeff, 'rid', ds.cid, 'cid', comp_labels);
res.pc_coeff = annotate_ds(res.pc_coeff, col_meta, 'dim', 'row');

% PC scores [N x P] rows = observations, columns = components
res.pc_score = mkgctstruct(pc_score, 'rid', ds.rid, 'cid', comp_labels);
res.pc_score = annotate_ds(res.pc_score, row_meta, 'dim', 'row');

% PC variance [P x 1] in descending order
res.pc_var = mkgctstruct(pc_var, 'rid', comp_labels, 'cid', {'PCA_VAR'});
res.pct_explained = mkgctstruct(pct_explained, 'rid', comp_labels, 'cid', {'PCA_VAR'});

% column means
res.col_mean = mkgctstruct(col_mean, 'cid', ds.cid, 'rid', {'COL_MEAN'});
res.col_mean = annotate_ds(res.col_mean, col_meta);

end
