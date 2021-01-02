function ds = ds_add_dummy_meta(ds, dim, req_fn)
% DS_ADD_DUMMY_META Insert dummy metadata fields to GCT structure

dim_str = get_dim2d(dim);
if ischar(req_fn)
    req_fn = {req_fn};
end
nfn = length(req_fn);
for ii=1:nfn
    switch (dim_str)
        case 'row'
            if ~ds.rdict.isKey(req_fn{ii})
                dbg(1, 'Inserting dummy Row metadata field: %s', req_fn{ii})
                ds = ds_add_meta(ds, 'row', req_fn{ii}, upper(req_fn{ii}));
            end            
        case 'column'
            if ~ds.cdict.isKey(req_fn{ii})
                dbg(1, 'Inserting dummy Column metadata field: %s', req_fn{ii})
                ds = ds_add_meta(ds, 'column', req_fn{ii}, upper(req_fn{ii}));
            end
    end
end
end