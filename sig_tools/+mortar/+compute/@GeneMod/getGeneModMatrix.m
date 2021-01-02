function res = getGeneModMatrix(aggzs, rid, topn)
%% for one feature, generate genemod matrix of pert_id x cell_id
assert(ischar(rid), 'rid should be a scalar string');
aggzs = ds_slice(aggzs, 'rid', {rid});

pert_id = ds_get_meta(aggzs, 'column', 'pert_id');
cell_id = ds_get_meta(aggzs, 'column', 'cell_id');
pert_iname = ds_get_meta(aggzs, 'column', 'pert_iname');
pert_type = ds_get_meta(aggzs, 'column', 'pert_type');

%% generate genemod matrix pert_id x cell_id
[pert_gp, pert_nl] = getcls(pert_id);
[cell_gp, cell_nl] = getcls(cell_id);

[~, uidx] = unique(pert_nl);

npert = length(pert_gp);
ncell = length(cell_gp);

gm = nan(npert, ncell);
for ii=1:npert
    idx = pert_nl==ii;
    cidx = cell_nl(idx);
    gm(ii, cidx) = aggzs.mat(1, idx);
end

gmds = mkgctstruct(gm, 'rid', pert_gp, 'cid', cell_gp);
gmds = ds_add_meta(gmds, 'row', {'pert_iname', 'pert_type'}, [pert_iname(uidx), pert_type(uidx)]);
gmds = sort_matrix(gmds);
topn = clip(topn, 1, length(gmds.rid));
gm_down = get_top(gmds, topn, false);
gm_up = get_top(gmds, topn, true);

res = struct('zs', aggzs,...
    'gm', gmds,...
    'topn_up', gm_up,...
    'topn_down', gm_down);
end

function ds = sort_matrix(ds)
% sort rows and columns gene mod matrix by degree of modulation

% number of non-nan elements 
is_not_nan = ~isnan(ds.mat);
row_nnan = sum(is_not_nan, 2);
col_nnan = sum(is_not_nan, 1);

% sort rows based on max quantile
row_maxq = max_quantile(ds.mat, 33, 67, 2);
% ignore rows with < 3 non-nan values
row_maxq(row_nnan < 3) = 0;
[~, ridx] = sort(row_maxq, 'descend');

% sort columns the same way
% col_q25 = q25(ds.mat, 1);
% col_q25(col_nnan < 3) = 0;
% [~, cidx] = sort(col_nnan, 'descend');
cidx = 1:size(ds.mat, 2);
ds = ds_slice(ds, 'ridx', ridx, 'cidx', cidx);
end

function x = get_top(gm, n, is_top)
nr = size(gm.mat, 1);
if is_top
    x = ds_slice(gm, 'ridx', 1:clip(n, 1, nr));
else
    x = ds_slice(gm, 'ridx', clip(nr-(0:n-1), 1, nr));
end
x = ds_delete_missing(x);
% x = sort_matrix(x);
end
