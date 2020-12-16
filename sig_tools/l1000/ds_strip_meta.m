function ds = ds_strip_meta(ds, dim)
% DS_STRIP_META Delete metadata fields from GCT structure.
% NEWDS = DS_STRIP_META(DS) removes both row and column metadata from DS
% NEWDS = DS_STRIP_META(DS, DIM) DIM can be 
%   'both' removes both row and column metadata
%   'row' remove only row metadata
%   'column' remove only column metadata
% 
if ~isvarexist('dim')
    dim = 'both';
else
    if strcmpi(dim, 'both')
        dim = 'both';
    else
        dim = get_dim2d(dim);
    end
end

switch(dim)
    case 'row'
        ds = ds_delete_meta(ds, 'row', ds.rhd);
    case 'column'
        ds = ds_delete_meta(ds, 'column', ds.chd);
    case 'both'
        ds = ds_delete_meta(ds, 'row', ds.rhd);
        ds = ds_delete_meta(ds, 'column', ds.chd);
end

end