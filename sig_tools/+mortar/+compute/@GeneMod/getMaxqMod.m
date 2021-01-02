function res = getMaxqMod(gmres)
% Get top-n modulators for each gene

npert = gmres.npert;
ngene = gmres.ngene;
ncell = gmres.ncell;

% GIGO! Assume that the matrix columns are ordered by gene:cell_id and that
% there are ncell*ngene columns
assert(isequal(ncell*ngene, size(gmres.gm.mat, 2)));

pert_id = gmres.gm.rid;
% cell_id = ds_get_meta(gmres.gm, 'column', 'cell_id');
pr_id = ds_get_meta(gmres.gm, 'column', 'pr_id');
gene_symbol = ds_get_meta(gmres.gm, 'column', 'pr_gene_symbol');

% make 3d matrix of pert x cell x gene
x = reshape(gmres.gm.mat, npert, ncell, ngene);
% max quantile pert x gene
mq = get_maxq(x, 33, 67);

[ugene_symbol, uidx]=unique(gene_symbol, 'stable');
cid = strcat(ugene_symbol,':','maxq');
mqds = mkgctstruct(mq, 'rid', pert_id, 'cid', cid);
mqds = ds_add_meta(mqds, 'column', {'pr_gene_symbol', 'pr_id'},...
                   [ ugene_symbol, pr_id(uidx)]);

res = struct('maxq', mqds);
% 
% n = clip(n, 1, npert);
% 
% topn_up = nan(n, ncell, ngene);
% topn_dn = nan(n, ncell, ngene);
% 
% for ii=1:ngene
%     srt = sort_matrix(gmres.gm(:,:, ii));
%     topn_up(:, :, ii) = get_top(srt, n, true);
%     topn_dn(:, :, ii) = get_top(srt, n, false);
% end
% 
% res = struct('topn_up', topn_up,...
%              'topn_dn', topn_dn,...
%              'x_id', {gmres.x_id},...
%              'y_id', {gmres.y_id},...
%              'z_id', {gmres.z_id});
end

function mq = get_maxq(x, p1, p2)

%TODO add num nan filter
    p = prctile(x, [p1, p2], 2);
    mq = p(:, 1, :);
    use_p2 = abs(p(:, 1,:)) < abs(p(:, 2,:));
    [ir, iz] = find(use_p2);
    mq(sub2ind(size(mq), ir, ones(size(ir)), iz)) = p(sub2ind(size(p),...
                                                        ir,...
                                                        2*ones(size(ir)),...
                                                        iz));
    mq = squeeze(mq);
end


function x = sort_matrix(x)
% sort rows and columns gene mod matrix by degree of modulation

% number of non-nan elements 
is_not_nan = ~isnan(x);
row_nnan = sum(is_not_nan, 2);
col_nnan = sum(is_not_nan, 1);

% sort rows based on max quantile
row_maxq = max_quantile(x, 33, 67, 2);
% ignore rows with < 3 non-nan values
row_maxq(row_nnan < 3) = 0;
[~, ridx] = sort(row_maxq, 'descend');

% sort columns the same way
% col_q25 = q25(ds.mat, 1);
% col_q25(col_nnan < 3) = 0;
% [~, cidx] = sort(col_nnan, 'descend');
cidx = 1:size(x, 2);
x = x(ridx, cidx);
end

function x = get_top(gm, n, is_top)
nr = size(gm, 1);
if is_top
    x = gm(1:clip(n, 1, nr), :);
else
    x = gm(clip(nr-(0:n-1), 1, nr), :);
end
% x = ds_delete_missing(x);
% x = sort_matrix(x);
end
