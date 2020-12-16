function tag = get_provenance(ds)

if isKey(ds.cdict, 'provenance_code')
    tag = ds_get_meta(ds, 'column', 'provenance_code');
else
    tag = cell(size(ds.mat, 2), 1);
end

end