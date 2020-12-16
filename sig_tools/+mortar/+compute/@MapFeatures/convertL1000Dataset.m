function aig_ds = convertL1000Dataset(ds, chip_info)
% CONVERTL1000DATASET Map dataset features from Affymetrix U133A to
% Entrez Gene-id
% OUT = CONVERTL1000DATASET(DS) Convert features in dataset DS
%   from Affymetrix identifiers to gene-ids.

ds = parse_gctx(ds);
%% slice to AIG space
%chip_info = mortar.common.Chip.get_chip(platform, feature_space);
pr_id = {chip_info.pr_id}';
gene_id = {chip_info.pr_gene_id}';
[cmn_id, ia, ib] = intersect(pr_id, ds.rid, 'stable');
d_rid = setdiff(ds.rid, cmn_id);
disp(d_rid);
dbg(1, 'Mapping %d/%d features to AIG and ignoring %d',...
    length(cmn_id), length(ds.rid), length(d_rid));
aig_ds = ds_slice(ds, 'rid', cmn_id);
row_meta = keepfield(chip_info,...
    {'pr_gene_id', 'pr_gene_symbol',...
    'pr_gene_title', 'pr_is_lm',...
    'pr_is_bing', 'pr_is_inf'});

aig_ds.rid = gene_id(ia);
aig_ds = annotate_ds(aig_ds, row_meta,...
    'dim', 'row', 'keyfield', 'pr_gene_id');
end