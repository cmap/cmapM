function runSummlyConn(ps, maxq_lo, maxq_hi, col_meta, row_meta, out_path)
% runDiffConn Run conn analysis by summarizing across queries and
% replicates
% vector
%   runSummlyConn(ps, maxq_param, col_meta, row_meta, out_path)
%
% PS: Connectivity matrix in GCT(x) format of tau (PS) values. Dimensions
%     are ref_perts x cps x cell lines
% MAXQ_LO: Lower quantile to use for Max quantile summarization
% MAXQ_HI: Upper quantile to use for Max quantile summarization
% COL_META: Column metadata table of PS with the first column corresponding
% to the column-ids in PS (need not be in the same order). Required fields
% ROW_META: Row metadata table of PS with the first column corresponding to
%     the row-ids in PS (need not be in the same order)
% OUT_PATH: Output folder
%
%
% Outputs:
%   <pert_iname>_ps.gctx : 
%   <pert_iname>_filt.gctx : Top scoring rows by MaxQ. All rows exceeding
%   ps_th are retained in addition to the top-N rows for each unique
%   pert_id
%   <pert_iname>_ps_maxq.gctx : MAX-Q values from filt matrix aggregated by
%               pert_iname, pert_type

col_meta = parse_record(col_meta);
assert(has_required_fields(col_meta,...
    {'sig_id', 'pert_iname'}, true),...
    'Missing required column meta data fields');
row_meta = parse_record(row_meta);
assert(has_required_fields(row_meta,...
    {'rid', 'pert_iname', 'pert_type'}, true),...
    'Missing required column meta data fields');

mkdirnotexist(out_path);

%%
    [gp_name, gp_idx] = getcls({col_meta.pert_iname}');
    ngp = length(gp_name);
    row_space = {row_meta.rid}';
    cid = {col_meta.sig_id}';
parfor ii=1:ngp
    dbg(1, '%d/%d %s', ii, ngp, gp_name{ii});
    this = gp_idx==ii;
    this_cid = cid(this);
    this_ps = parse_gctx(ps, 'cid', this_cid);
    % filter to row_space
    this_ps = ds_slice(this_ps, 'rid', row_space);
    this_ps = annotate_ds(this_ps, row_meta, 'dim', 'row', 'keyfield', 'rid');
    
    % row-wise max quantile
    max_q = max_quantile(this_ps.mat, maxq_lo, maxq_hi, 2);
    this_ps = ds_add_meta(this_ps, 'row', 'max_q', num2cell(max_q));
    
    % filter rows to significant connections by max_q
    this_ps_filt = mortar.compute.DiffConn.filterBestConnections(this_ps, 'max_q', 85, 2);    
    
    % MAX_Q dataset
    max_q_filt = ds_get_meta(this_ps_filt, 'row', 'max_q');
    ds_max_q = mkgctstruct(max_q_filt, 'rid', this_ps_filt.rid, 'cid', gp_name(ii));
    ds_max_q = annotate_ds(ds_max_q, gctmeta(this_ps_filt, 'row'), 'dim', 'row');    
    ds_max_q_agg = ds_aggregate(ds_max_q, 'row_fields', {'pert_iname', 'pert_type'}, 'fun', 'median');
           
    this_out = fullfile(out_path, sprintf('%s_ps.gctx', gp_name{ii}));
    % Unfiltered matrix with all ref signatures
    mkgctx(this_out, this_ps)
    % Filtered matrix with best connections
    this_out_filt = fullfile(out_path, sprintf('%s_ps_filt.gctx', gp_name{ii}));
    mkgctx(this_out_filt, this_ps_filt)
    % Aggregated MAX_Q dataset
    this_out_maxq = fullfile(out_path, sprintf('%s_ps_maxq.gctx', gp_name{ii}));
    mkgctx(this_out_maxq, ds_max_q_agg)

end
end