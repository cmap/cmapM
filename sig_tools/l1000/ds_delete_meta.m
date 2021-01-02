function ds = ds_delete_meta(ds, dim, hd)
% DS_DELETE_META Delete metadata fields from GCT structure.
% NEWDS = DS_DELETE_META(DS, DIM, HD)

if ischar(hd)
    hd = {hd};
end
nmeta = length(hd);
switch(lower(dim))
    case 'row'
        iskey = ds.rdict.isKey(hd);
        if ~isequal(nnz(iskey), nmeta)
            disp(hd(~iskey))
            warning('ds_delete_meta:KeysMissing', 'Some fields not found');
        end
        if nnz(iskey)
            del_idx = cell2mat(ds.rdict.values(hd(iskey)));
            ds.rhd(del_idx) = [];
            ds.rdesc(:, del_idx) = [];
            ds.rdict = list2dict(ds.rhd);
        end

    case 'column'
        iskey = ds.cdict.isKey(hd);
        if ~all(iskey)
            disp(hd(~iskey))
            warning('ds_delete_meta:KeysMissing', 'Some fields not found');
        end
        if any(iskey)
            del_idx = cell2mat(ds.cdict.values(hd(iskey)));
            ds.chd(del_idx) = [];
            ds.cdesc(:, del_idx) = [];
            ds.cdict = list2dict(ds.chd);
        end
    otherwise
        error('Dim should be ''row'' or ''column''')
end
end
