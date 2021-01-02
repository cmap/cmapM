function nb_rpt = getIntrospectNeighbors(cc_ds, index_tbl, sim_th)
% getIntrospectNeighbors Lookup nearest neighbors of index entries from a 
%   similarity matrix
%   RPT = getIntrospectNeighbors(CC_DS, INDEX_TBL, SIM_TH)

cc_ds = parse_gctx(cc_ds);
index_tbl = parse_record(index_tbl);
%index_req_fn = {'set_id', 'xicon_iname', 'xicon_score', 'xicon_col_pct_rank', 'xicon_row_pct_rank'};
index_req_fn = {'set_id'};
assert(has_required_fields(index_tbl, index_req_fn), 'Index table is missing required fields');
set_id = {index_tbl.set_id}';
cc_ds = ds_slice(cc_ds, 'cid', set_id);

% mask self similarities
[c, ir, ic] = intersect(cc_ds.rid, cc_ds.cid);
dbg(1, 'Masking %d self connections', length(c));
ind = sub2ind(size(cc_ds.mat), ir, ic);
cc_ds.mat(ind) = nan;

is_sim = cc_ds.mat>=sim_th;

nb_rpt = ds_get_hits(cc_ds, is_sim);

end