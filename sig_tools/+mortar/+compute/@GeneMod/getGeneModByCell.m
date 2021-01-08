function res = getGeneModByCell(aggzs)
%% Generate genemod matrix of pert_id x cell_id x features

pert_id = ds_get_meta(aggzs, 'column', 'pert_id');
cell_id = ds_get_meta(aggzs, 'column', 'cell_id');
pert_iname = ds_get_meta(aggzs, 'column', 'pert_iname');
pert_type = ds_get_meta(aggzs, 'column', 'pert_type');

%% generate genemod matrix pert_id x cell_id
[ngene, ncol] = size(aggzs.mat);
[pert_gp, pert_nl] = getcls(pert_id);
[cell_gp, cell_nl] = getcls(cell_id);
npert = length(pert_gp);
ncell = length(cell_gp);

pert_idx = reshape(repmat(pert_nl', ngene, 1), ngene*ncol, 1);
cell_idx = reshape(repmat(cell_nl', ngene, 1), ngene*ncol, 1);
gene_idx = reshape(repmat((1:ngene)', 1, ncol), ngene*ncol, 1);

% 3d matrix pert x cell x gene
% gm = nan(npert, ncell, ngene);
% gm(sub2ind(size(gm), pert_idx, cell_idx, gene_idx)) = aggzs.mat(:);
% res = struct('gm', gm,...
%     'x_id', {cell_gp},...
%     'y_id', {pert_gp},...
%     'z_id', {aggzs.rid});

% 2d matrix pert x (cell*gene)
gm = nan(npert, ncell*ngene);
gm(sub2ind(size(gm), pert_idx, cell_idx+(gene_idx-1)*ncell)) = aggzs.mat(:);

res_cell_id = repmat(cell_gp, ngene,1);
res_pr_id = reshape(repmat(aggzs.rid, 1, ncell)', ncell*ngene, 1);

%gene_meta = gene_info(res_pr_id, 'field', {'pr_id', 'pr_gene_symbol'});
gene_meta = gctmeta(aggzs, 'row');
gs_lut = mortar.containers.Dict({gene_meta.rid}', {gene_meta.pr_gene_symbol}');
%res_gene_symbol = {gene_meta.pr_gene_symbol}';
res_gene_symbol = gs_lut(res_pr_id);
cid = strcat(res_gene_symbol, ':', res_cell_id);
col_meta_fields = {'pr_gene_symbol', 'pr_id', 'cell_id'};
col_meta =  [res_gene_symbol, res_pr_id, res_cell_id];

gmds = mkgctstruct(gm, 'rid', pert_gp, 'cid', cid, 'chd', col_meta_fields,...
                  'cdesc', col_meta);

res = struct('gm', gmds,...
             'npert', npert,...
             'ncell', ncell,...
             'ngene', ngene);
end

