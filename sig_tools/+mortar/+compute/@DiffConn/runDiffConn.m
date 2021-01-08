function runDiffConn(ps, pheno, row_meta, out_path)
% runDiffConn Run diff conn analysis against a user-defined phenotype
% vector
%   runDiffConn(ps, pheno, row_meta, out_path)
%
% PS: Connectivity matrix in GCT(x) format of tau (PS) values. Dimensions
%     are ref_perts x cps x cell lines
% PHENO: Phenotype table with at least the following fields:
%     sig_id : signature id, corresponding to column ids of PS
%     pert_iname: compound name
%     phenotype_vec: integer values 1=sens, -1=insens, 0=ignore
% ROW_META: Row metadata table of PS with the first column corresponding to
%     the row-ids in PS (need not be in the same order)
% OUT_PATH: Output folder
%
% The function computes several Differential connectivity metrics for each
% unique pert_iname in the PHENO file.
%
% Outputs:
%   <pert_iname>_ps.gctx
%   <pert_iname>_filt.gctx


pheno_all = parse_record(pheno);
assert(has_required_fields(pheno_all,...
    {'sig_id', 'pert_iname', 'phenotype_vec'}, true),...
    'Missing required row meta data fields');

% keep only phenotype selections
is_pick = abs([pheno_all.phenotype_vec]')>0;
pheno = pheno_all(is_pick);

ps_annot = parse_gctx(ps, 'annot_only', true);
col_meta = gctmeta(ps_annot);
row_meta = parse_record(row_meta);
assert(has_required_fields(row_meta, {'rid'}, true),...
    'Missing required row meta data fields');

mkdirnotexist(out_path);

%%
    [gp_name, gp_idx] = getcls({pheno.pert_iname}');
    ngp = length(gp_name);
    row_space = {row_meta.rid}';
parfor ii=1:ngp
    dbg(1, '%d/%d %s', ii, ngp, gp_name{ii});
    this = gp_idx==ii;
    this_pheno = pheno(this);
    % reorder by phenotype vector and score
%     [~, col_ord] = sorton([[this_pheno.phenotype_vec]',...
%         [this_pheno.modz_core_72h]'], [1,2], 1, {'descend', 'ascend'});
    [~, col_ord] = sort([this_pheno.phenotype_vec]', 1, 'descend');
    
    this_pheno = this_pheno(col_ord);
    [this_cid, ia, ib] = intersect({this_pheno.sig_id}', {col_meta.cid}', 'stable');
    this_ps = parse_gctx(ps, 'cid', this_cid);
    % filter to row_space
    this_ps = ds_slice(this_ps, 'rid', row_space);
    this_ps = annotate_ds(this_ps, this_pheno, 'keyfield', 'sig_id', 'append', false);
    this_ps = annotate_ds(this_ps, row_meta, 'dim', 'row', 'keyfield', 'rid');
    dc_metrics = mortar.compute.DiffConn.diffConnMetrics(this_ps, 'phenotype_vec');
    this_ps = annotate_ds(this_ps, dc_metrics, 'dim', 'row', 'append', false);
    % order by dc_score
    [~, ridx] = sort(ds_get_meta(this_ps, 'row', 'dc_score'), 'descend');
    this_ps = ds_slice(this_ps, 'ridx', ridx);
    
    % filter rows to significant connections
    this_ps_filt = mortar.compute.DiffConn.filterBestConnections(this_ps, 'pos_q', 2);
    this_out = fullfile(out_path, sprintf('%s_ps.gctx', gp_name{ii}));
    % Unfiltered matrix with all ref signatures
    mkgctx(this_out, this_ps)
    % Filtered matrix with best connections
    this_out_filt = fullfile(out_path, sprintf('%s_ps_filt.gctx', gp_name{ii}));
    mkgctx(this_out_filt, this_ps_filt)
%     % Text report of best connections per reference pert
%     this_out_filt_rpt = fullfile(out_path, sprintf('%s_diffconn_rpt.txt', gp_name{ii}));
%     jmktbl(this_out_filt_rpt, gctmeta(this_ps_filt, 'row'));
end
end