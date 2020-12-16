function subsets = subsetIntrospect(cs, cs_col_meta, pert_info, cp_sensitivity, moa_sensitivity)
% subsetIntrospect : Select subset of introspect and re-order cell lines
% based on sensitivity
% subsets = subsetIntrospect(cs, cs_col_meta, pert_info, cp_sensitivity, moa_sensitivity) 

cp_sensitivity = parse_gctx(cp_sensitivity);
moa_sensitivity = parse_gctx(moa_sensitivity);

sig_id_field = 'sig_id';
cp_name_field = 'pert_iname';
moa_field = 'moa';
cell_line_field = 'cell_id';

% Join pert info if provided, mainly to update moa membership
if ~isempty(pert_info)
    dbg(1, 'Joining metadata from pert_info');
    pert_info = parse_record(pert_info);
    cs_col_meta = join_table(cs_col_meta, pert_info, cp_name_field, cp_name_field);
end

% Validate inputs
req_fn = {sig_id_field, cp_name_field, moa_field, cell_line_field};
assert(has_required_fields(cs_col_meta, req_fn),...
    'cs_col_meta is missing required fields')
assert(is_ds_field(cp_sensitivity, {cp_name_field}, 'column'),...
    sprintf('cp_sensitivity is missing COLUMN annotation: %s', cp_name_field))
assert(is_ds_field(cp_sensitivity, {cell_line_field}, 'row'),...
    sprintf('cp_sensitivity is missing ROW annotation: %s', cell_line_field))
assert(is_ds_field(moa_sensitivity, {moa_field}, 'column'),...
    sprintf('moa_sensitivity is missing COLUMN annotation: %s', moa_field))
assert(is_ds_field(moa_sensitivity, {cell_line_field}, 'row'),...
    sprintf('moa_sensitivity is missing ROW annotation: %s', cell_line_field))

% Cp sens annotations
cp_name = ds_get_meta(cp_sensitivity, 'column', cp_name_field);
cp_cell_id = ds_get_meta(cp_sensitivity, 'row', cell_line_field);

% MoA annotations
moa_name = ds_get_meta(moa_sensitivity, 'column', moa_field);
moa_cell_id = ds_get_meta(moa_sensitivity, 'row', cell_line_field);
% cell lines for cp_sens and moa_sens matrices should match
[cmn_cell, cp_sens_ridx, moa_sens_ridx] = intersect(cp_cell_id, moa_cell_id, 'stable');
assert(isequal(length(cmn_cell), length(cp_cell_id)),...
    'cell lines for cp_sens and moa_sens matrices should match');
% sync order of cell lines
moa_sensitivity = ds_slice(moa_sensitivity, 'ridx', moa_sens_ridx);
moa_cell_id = ds_get_meta(moa_sensitivity, 'row', cell_line_field);

% CS annotations
% filter cs_col_meta to cell lines with sensitvity
keep_cell_line = ismember({cs_col_meta.(cell_line_field)}', cmn_cell);
cs_col_meta_filt = cs_col_meta(keep_cell_line);

cs_cp_name = {cs_col_meta_filt.(cp_name_field)}';
cs_cp_moa = {cs_col_meta_filt.(moa_field)}';
cs_cell_line = {cs_col_meta_filt.(cell_line_field)}';

moa_lut = mortar.containers.Dict(cs_cp_name, cs_cp_moa);

% common cps
[cmn_cp, ia, ib] = intersect(cs_cp_name, cp_name);
cmn_moa = moa_lut(cmn_cp);
num_cp = length(cmn_cp);

subsets = cell(num_cp, 1);

for ii=1:num_cp
    this_cp = cmn_cp{ii};
    this_moa = moa_lut(this_cp);
    this_moa = this_moa{1};
    cs_idx = strcmp(cs_cp_name, this_cp);
    this_subset = cs_col_meta_filt(cs_idx);
    this_sig_id = {this_subset.(sig_id_field)}';
    dbg(1, '%d/%d %s (%s)', ii, num_cp, this_cp, this_moa);
        
    % Join cp and MoA Sensitivity
    cp_sens_cidx = strcmp(cp_name, this_cp);
    this_cp_sens = ds_slice(cp_sensitivity, 'cidx', cp_sens_cidx);
    cp_sens_tbl = struct(cell_line_field, cp_cell_id, 'cp_sens', num2cell(this_cp_sens.mat));
    this_subset = join_table(this_subset, cp_sens_tbl, cell_line_field, cell_line_field);
    
    moa_sens_cidx = strcmp(moa_name, this_moa);
    if nnz(moa_sens_cidx)
        this_moa_sens = ds_slice(moa_sensitivity, 'cidx', moa_sens_cidx);
        moa_sens_tbl = struct(cell_line_field, moa_cell_id, 'moa_sens', num2cell(this_moa_sens.mat));
    else
        moa_sens_tbl = struct(cell_line_field, moa_cell_id, 'moa_sens', nan);
    end
    this_subset = join_table(this_subset, moa_sens_tbl, cell_line_field, cell_line_field);
    
    % subset of CS matrix, for corr_sens computation
    this_cs = parse_gctx(cs, 'cid', this_sig_id);
    this_cs = ds_slice(this_cs, 'rid', this_sig_id);
    this_cs = annotate_ds(this_cs, this_subset, 'append', false);
    this_cs = annotate_ds(this_cs, this_subset, 'dim', 'row', 'append', false);
    
    % compute correlation to sens vector for reordering the cell lines
    this_sens = ds_get_meta(this_cs, 'column', 'cp_sens');
    sens_idx = find(this_sens>0);
    [cc_sens, sens_vec] = mortar.compute.DiffConn.corrMatrixToGroup(this_cs.mat, sens_idx, 'median', 'pearson');
    this_cs = ds_add_meta(this_cs, 'column', 'corr_sens', num2cell(cc_sens));
    this_cs = ds_add_meta(this_cs, 'row', 'corr_sens', num2cell(cc_sens));
    [srt, srt_idx] = sorton([this_sens, cc_sens], [1, 2], 1, {'descend', 'descend'});
    this_cs = ds_slice(this_cs, 'cidx', srt_idx, 'ridx', srt_idx);
    subsets{ii} = this_cs;
end

end