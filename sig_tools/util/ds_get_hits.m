function rpt = ds_get_hits(ds, hits)
% DS_GET_HITS Extract specified values from dataset
% T = DS_GET_HITS(DS, H) extracts values from DS
% corresponding to a logical matrix H that has the same dimensions as
% DS.MAT. T is a structure with as many rows as non-zeros in H with a
% minimum of the following fields : 'id', 'row_rid', 'col_cid', 'hit_value'
% In addition row and column meta-data fields from DS are also included.

row_meta = gctmeta(ds, 'row');
col_meta = gctmeta(ds, 'column');

if isvector(hits) && ~islogical(hits)
    % vector of indices into ds.mat
    hit_idx = hits(:);
    [ir, ic] = ind2sub(size(ds.mat), hit_idx);
else    
    % matrix of size ds.mat
    assert(isequal(size(ds.mat), size(hits)),...
           'size mismatch between hits and ds');    
    hit_idx = find(hits>0);
    [ir, ic] = ind2sub(size(ds.mat), hit_idx);
end

ds_row_rank = score2rank(ds, 'dim', 'row', 'as_percentile', true); 
ds_col_rank = score2rank(ds, 'dim', 'column', 'as_percentile', true);

hit_val = ds.mat(hit_idx);
hit_row_rank = ds_row_rank.mat(hit_idx);
hit_col_rank = ds_col_rank.mat(hit_idx);

row_rpt = row_meta(ir(:));
row_fn = fieldnames(row_rpt);
new_row_fn = strcat('row_', row_fn);
row_rpt = mvfield(row_rpt, row_fn, new_row_fn);

col_rpt = col_meta(ic(:));
col_fn = fieldnames(col_rpt);
new_col_fn = strcat('col_', col_fn);
col_rpt = mvfield(col_rpt, col_fn, new_col_fn);
rpt = mergestruct(row_rpt, col_rpt);
id = strcat({rpt.row_rid}', '|', {rpt.col_cid}');
%[rpt.hit_value] = hit_val_cell{:};
%[rpt.id] = id{:};
rpt = setarrayfield(rpt, [],...
    {'id', 'hit_value', 'hit_row_pct_rank', 'hit_col_pct_rank'},...
    id, hit_val, hit_row_rank, hit_col_rank);

rpt = orderfields(rpt, orderas(fieldnames(rpt), {'id', 'row_rid', 'col_cid'}));

end