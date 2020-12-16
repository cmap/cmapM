function ds = update_provenance(ds, process, alg, varargin)

if ds.cdict.isKey('provenance_code')
    tag = ds_get_meta(ds,  'column', 'provenance_code');
else
    tag = cell(size(ds.cid));
end

tag = get_process_code(tag, process, alg, varargin{:});

ds = ds_add_meta(ds, 'column', {'provenance_code'}, tag);

end