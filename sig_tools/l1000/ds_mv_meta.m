function ds = ds_mv_meta(ds, dim, hd, new_hd)
% DS_MV_META Rename meta data fields in a GCT datastructure
% NEWDS = DS_MV_META(DS, DIM, HD, NEWHD)

if ischar(hd)
    hd = {hd};
end
nhd = length(hd);
if ischar(new_hd)
    new_hd = {new_hd};
end

assert(isequal(nhd, length(new_hd)), 'Lengths of new and old fieldnames must be equal')

switch(lower(dim))
    case 'row'
        isk = ds.rdict.isKey(hd);
        isknew = ds.rdict.isKey(new_hd);
        
        if ~(all(isk))
            disp(hd(~isk));
            error('Some fieldnames not found');
        end      
        
        if any(isknew)
            disp(new_hd(isknew));
            error('Some new fieldnames collide with exsting fields');
        end      
        
        [~, iold, inew] = intersect(ds.rhd, hd, 'stable');
        ds.rhd(iold) = new_hd(inew);
        ds.rdict = list2dict(ds.rhd);
    case 'column'
        isk = ds.cdict.isKey(hd);
        isknew = ds.cdict.isKey(new_hd);
        if ~(all(isk))
            disp(hd(~isk));
            error('Some fieldnames not found');
        end      
        if any(isknew)
            disp(new_hd(isknew));
            error('Some new fieldnames collide with exsting fields');
        end

        [~, iold, inew] = intersect(ds.chd, hd, 'stable');
        ds.chd(iold) = new_hd(inew);
        ds.cdict = list2dict(ds.chd);

    otherwise
        error('Dim should be ''row'' or ''column''')
end
end
