function res = mapEnsemblToL1000(ds)
% mapEnsemblToL1000 Map features from ensembl gene ids to L1000 AIG
% features.
% RES = mapEnsemblToL1000(DS) Convert features from features in dataset DS 
%   from ensembl identifiers to L1000 ids.

ds = parse_gctx(ds);
%% strip suffix after the dot from feature ids
% Assumes that the row-ids in DS has ensemble gene ids (suffixes after a
% dot are ignored from the identifiers)
has_dot = ~cellfun(@isempty, strfind(ds.rid, '.'));
if any(has_dot)
    ensgid = cellfun(@(x) x{1}, tokenize(ds.rid,'.'), 'unif', false);
else
    ensgid = ds.rid;
end
ensgid2rid_lut = mortar.containers.Dict(ensgid, ds.rid);

%% Apply feature mapping from ensembl to Entrez ids
% one-to-many map possible # 1311
% many-to-one map also possible # 376
% map ensembl to entrez
ensembl_to_entrez = mortar.common.Chip.get_chip('ensembl', 'all');
entrez = mortar.common.Chip.get_chip('entrez', 'all');
l1k_aig = mortar.common.Chip.get_chip('l1000', 'aig');

%% ensembl ids matching chip file
ens_match = ismember({ensembl_to_entrez.ensembl_gene_id}, ensgid);
dbg(1, '%d/%d feature ids match ensemble chip file', nnz(ens_match), numel(ensgid));

%%
feature_map = struct('dsid', ensgid2rid_lut({ensembl_to_entrez(ens_match).ensembl_gene_id}'),...
             'ensgid', {ensembl_to_entrez(ens_match).ensembl_gene_id}',...
             'ezid', {ensembl_to_entrez(ens_match).entrez_gene_id}');
%%
ds_ridx_lut = mortar.containers.Dict(ds.rid);
[gpv, gpn, gpi] = get_groupvar(feature_map, fieldnames(feature_map), 'ezid');
ngp = length(gpn);
[nr, nc] = size(ds.mat);
%% Aggregate values for each entrez gene_id using max 
dbg(1, 'Aggregating %d unique entrez gene ids', numel(unique(ensgid(ens_match))));
aggmat = zeros(ngp, nc);
for ii=1:ngp
    this = gpi ==ii;
    nthis = numel(this);
    this_ridx = ds_ridx_lut({feature_map(this).dsid});
    if nthis>1
        aggmat(ii, :) = max(ds.mat(this_ridx, :), [], 1);
    else
        aggmat(ii, :) = ds.mat(this_ridx, :);
    end
end

%%
ezid_ds = mkgctstruct(aggmat, 'rid', gpn, 'cid', ds.cid);
missing_rid = setdiff(ezid_ds.rid, {entrez.pr_gene_id});
if numel(missing_rid)
    disp(missing_rid);
    dbg(1, '%d entrez-ids not in L1K AIG space, ignoring them', numel(missing_rid));
end
ezid_ds = ds_slice(ezid_ds, 'rid', intersect_ord({entrez.pr_gene_id}, ezid_ds.rid));
ezid_ds = annotate_ds(ezid_ds, entrez, 'dim', 'row');
ezid_ds = annotate_ds(ezid_ds, gctmeta(ds));
%% annnotate with AIG probes
[c, ia, ib] = intersect(ezid_ds.rid, {l1k_aig.pr_gene_id});
aig_map = struct('dsid', ezid_ds.rid(ia), 'l1k_pr_id', {l1k_aig(ib).pr_id}');
ezid_ds = annotate_ds(ezid_ds,aig_map,'dim','row','skipmissing',true);

aig_ds = ds_slice(ezid_ds, 'ridx', ia);
ez_id = aig_ds.rid;
aig_ds.rid = ds_get_meta(aig_ds, 'row', 'l1k_pr_id');
aig_ds = ds_add_meta(aig_ds, 'row', 'pr_gene_id', ez_id);
aig_ds = ds_delete_meta(aig_ds, 'row', 'l1k_pr_id');

res = struct('ds', ds, 'ezid_ds', ezid_ds, 'aig_ds', aig_ds);