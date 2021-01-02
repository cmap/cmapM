function [hit_val, rmeta, cmeta, idx_all] = ds_find_pairs(ds, row_val, col_val, row_fn, col_fn)
% DS_FIND_PAIRS Lookup dataset values corresponding to pairs of 
%   meta-data identifiers
%   [V, RMETA, CMETA, IDX] = DS_FIND_PAIRS(DS, ROW_VAL, COL_VAL, ROW_FN, COL_FN)

col_meta = gctmeta(ds);
row_meta = gctmeta(ds, 'row');
[row_gpv, row_gpn, row_gpi] = get_groupvar(row_meta, [], row_fn);
[col_gpv, col_gpn, col_gpi] = get_groupvar(col_meta, [], col_fn);

% lookup table for rows
[rgpn, rgpc] = group2cell((1:length(row_gpi))', row_gpv);
row_lut = mortar.containers.Dict(rgpn, rgpc);

[cgpn, cgpc] = group2cell((1:length(col_gpi))', col_gpv);
col_lut = mortar.containers.Dict(cgpn, cgpc);

row_exists = row_lut.isKey(row_val);
col_exists = col_lut.isKey(col_val);
pair_exists = row_exists & col_exists;

dbg(1, '%d/%d of search pairs found',...
    nnz(pair_exists), length(pair_exists));
row_idx_cell = row_lut(row_val(pair_exists));
col_idx_cell = col_lut(col_val(pair_exists));

row_idx_sz = cellfun(@length, row_idx_cell);
col_idx_sz = cellfun(@length, col_idx_cell);
max_idx_sz = max(row_idx_sz, col_idx_sz);

% cases one to many or on-one matches
is_otm = row_idx_sz < 2 | col_idx_sz <2;
% many to many matches
is_mtm = ~is_otm;
if any(is_otm)
    dbg(1, 'Resolving %d one-one or one-many matches', nnz(is_otm))
    row_grp_sz = ones(size(row_idx_sz));
    is_row_sz_diff = abs(row_idx_sz - max_idx_sz) >0;
    row_grp_sz(is_row_sz_diff) = max_idx_sz(is_row_sz_diff);
    
    col_grp_sz = ones(size(col_idx_sz));
    is_col_sz_diff = abs(col_idx_sz - max_idx_sz) >0;
    col_grp_sz(is_col_sz_diff) = max_idx_sz(is_col_sz_diff);
    
    r_otm = row_idx_cell(grpsize2idx(row_grp_sz(is_otm), find(is_otm)));
    c_otm = col_idx_cell(grpsize2idx(col_grp_sz(is_otm), find(is_otm)));
    row_otm_idx = cat(1, r_otm{:});
    col_otm_idx = cat(1, c_otm{:});
    idx_otm = sub2ind(size(ds.mat), row_otm_idx, col_otm_idx);
else
    row_otm_idx = [];
    col_otm_idx = [];
    idx_otm = [];        
end

if any(is_mtm)
    dbg(1, 'Resolving %d many-many matches', nnz(is_mtm))
    mtm_idx = find(is_mtm);
    nmtm = length(mtm_idx);
    r_mtm = cell(nmtm, 1);
    c_mtm = cell(nmtm, 1);
    for ii=1:nmtm
        this_ridx = row_idx_cell{mtm_idx(ii)};
        this_cidx = col_idx_cell{mtm_idx(ii)};
        [ir, ic] = find(true(length(this_ridx), length(this_cidx)));
        r_mtm{ii} = this_ridx(ir);
        c_mtm{ii} = this_cidx(ic);
    end
    row_mtm_idx = cat(1, r_mtm{:});
    col_mtm_idx = cat(1, c_mtm{:});
    idx_mtm = sub2ind(size(ds.mat), row_mtm_idx, col_mtm_idx);
else
    row_mtm_idx = [];
    col_mtm_idx = [];
    idx_mtm = [];    
end

row_idx_all = [row_otm_idx; row_mtm_idx];
col_idx_all = [col_otm_idx; col_mtm_idx];
idx_all = [idx_otm; idx_mtm];

rmeta = row_meta(row_idx_all);
cmeta = col_meta(col_idx_all);
hit_val = ds.mat(idx_all);

end