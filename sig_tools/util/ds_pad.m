function ds = ds_pad(ds, rid, cid, missing_val)
% DS_PAD Resize a dataset to include specified row and column space
% ds = ds_pad(ds, rid, cid, missing_val)
if ~isempty(rid)
    missing_rid = setdiff(rid, ds.rid);
else
    missing_rid = '';
end

if ~isempty(cid)
    missing_cid = setdiff(cid, ds.cid);
else
    missing_cid = '';
end

nmiss_rid = numel(missing_rid);
nmiss_cid = numel(missing_cid);

if ~isempty(missing_rid)
    nc = size(ds.mat, 2);
    row_ds = mkgctstruct(ones(nmiss_rid, nc)*missing_val, 'rid', missing_rid, 'cid', ds.cid);
    ds = merge_two(ds, row_ds);
end

if ~isempty(missing_cid)
    nr = size(ds.mat, 1);
    col_ds = mkgctstruct(ones(nr, nmiss_cid)*missing_val, 'cid', missing_cid, 'rid', ds.rid);
    ds = merge_two(ds, col_ds);
end
ds = ds_slice(ds, 'rid', rid, 'cid', cid);

end