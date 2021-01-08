function xicon_results = getXiconResults(ds, xicon_rpt)

ds = parse_gctx(ds);

req_col_fn = unique({xicon_rpt.xicon_match_field}');
assert(all(ds.cdict.isKey(req_col_fn)),...
    'Required column fields not found in DS');

% keep dataset as provided instead of slicing to avoid ranking externally
%cidx = ismember(ds_get_meta(ds, 'column', req_col_fn),...
%                {xicon_rpt.xicon_match_value}');

row_meta = gctmeta(ds, 'row');
col_meta = gctmeta(ds, 'column');
rid_lut = mortar.containers.Dict(ds.rid);
cid_lut = mortar.containers.Dict(ds.cid);
[xicon_pert_id, xicon_gpn, xicon_gpi] = get_groupvar(xicon_rpt, {}, 'xicon_match_value');
[col_pert_id, col_gpn, col_gpi] = get_groupvar(col_meta, {}, req_col_fn);
ngp = length(xicon_gpn);
xicon_mat = zeros(size(ds.mat));
is_pert_in_ds=ismember(xicon_gpn, col_gpn);

for ii=1:ngp
    if is_pert_in_ds(ii)
        this_pert_id = xicon_gpn{ii};
        this_cidx = strcmp(col_pert_id, this_pert_id);
        this_xicon = strcmp(xicon_pert_id, this_pert_id);
        this_ds_rid = {xicon_rpt(this_xicon).member_id}';
        this_ridx = rid_lut(this_ds_rid);
        cnx_val = repmat(find(this_xicon), 1, nnz(this_cidx));
        xicon_mat(this_ridx, this_cidx) = cnx_val;
    end
end

is_hit = xicon_mat>0;
xicon_results = ds_get_hits(ds, is_hit);
xicon_results = mvfield(xicon_results,...
    {'hit_value', 'hit_col_pct_rank', 'hit_row_pct_rank'},...
    {'xicon_score', 'xicon_col_pct_rank', 'xicon_row_pct_rank'});
xicon_type = {xicon_rpt(xicon_mat(is_hit)).xicon_type}';
xicon_results = setarrayfield(xicon_results, [],...
    {'xicon_type'},...
    xicon_type);

end