function new_ds = ds_melt(ds)

ds = parse_gctx(ds);
row_meta = gctmeta(ds, 'row');
col_meta = gctmeta(ds);

[ir, ic] = find(ones(size(ds.mat)));
newmat = ds.mat(:);
new_meta = mergestruct(row_meta(ir), col_meta(ic));
new_rid = strcat({new_meta.rid}', ':', {new_meta.cid}');
new_meta = setarrayfield(new_meta, [], 'id', new_rid);
new_ds = mkgctstruct(newmat, 'rid', new_rid, 'cid', {'value'});
new_ds = annotate_ds(new_ds, new_meta, 'dim', 'row', 'keyfield', 'id');

end