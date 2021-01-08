function res = getTopMod(gmres, n)
% Get top-n modulators for each gene

% [npert, ncell, ngene] = size(gmres.gm);
npert = gmres.npert;
ngene = gmres.ngene;
ncell = gmres.ncell;

pr_id = ds_get_meta(gmres.gm, 'column', 'pr_id');
[pr_gp, pr_idx] = getcls(pr_id);

n = clip(n, 1, npert);

res = struct('pr_id', pr_gp, 'topn_up', '', 'topn_dn', '');
% topn_up = nan(n, ncell*ngene);
% topn_dn = nan(n, ncell*ngene);
for ii=1:ngene
    this_pr = pr_idx == ii;
    this_ds = ds_slice(gmres.gm, 'cid', gmres.gm.cid(this_pr));
    srt_ds = sort_matrix(this_ds);
    res(ii).topn_up = get_top(srt_ds, n, true);
    res(ii).topn_dn = get_top(srt_ds, n, false);
end

end

function x = sort_matrix(ds)
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
x = ds_slice(ds, 'ridx', ridx, 'cidx', cidx);
% x = x(ridx, cidx);
end

function topn = get_top(gm, n, is_top)
nr = size(gm.mat, 1);
if is_top
    ridx = 1:clip(n, 1, nr);
else
    ridx = clip(nr-(0:n-1), 1, nr);
end
topn = ds_slice(gm, 'ridx', ridx);
topn = ds_delete_missing(topn);
% x = sort_matrix(x);
end
