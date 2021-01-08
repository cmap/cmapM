function [pheno_cc, pheno_vec, srt_ord] = dsPhenotypeCorr(ds, is_pos_gp)
% dsPhenotypeCorr Compute the correlation of columns of a dataset to a 
% [pheno_cc, pheno_vec, srt_ord] = dsPhenotypeCorr(ds, is_pos_gp)
% wrapper around corrMatrixToGroup that operates on a dataset.
% See corrMatrixToGroup

ds = parse_gctx(ds);
[nr, nc] = size(ds.mat);
ne = numel(is_pos_gp);
assert(isequal(ne, nc),...
    'Number of elements in is_pos_gp should equal number of columns in ds. Expected %d got %d instead', nc, ne);
agg_fun = 'median';
corr_metric = 'pearson';
[pheno_cc, pheno_vec, srt_ord] = ...
    mortar.compute.DiffConn.corrMatrixToGroup(ds.mat, is_pos_gp, agg_fun, corr_metric);

end