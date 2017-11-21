function metadata = ds_get_meta(ds, dim, meta, varargin)
% DS_GET_META Extract metadata fields from a GCT structure
%
% METADATA = DS_GET_META(DS, DIM, META) Extracts metadata from DS.
% DIM may be 'row' or 'column', META is a string giving the field name
% to be extracted, or a cell array of strings giving the desired fields.
% If META is '_id' the corresponding row or column id is returned.
%
% METADATA = DS_GET_META(DS, DIM, META, IGNORE_MISSING) if IGNORE_MISSING
% is true, ignore missing fields.

metadata = ds_get_meta(ds, dim, meta, varargin{:});

end