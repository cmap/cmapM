function metadata = ds_get_meta(ds, dim, meta, ignore_missing)
% DS_GET_META Extract metadata fields from .gct file 
%
% METADATA = DS_GET_META(DS, DIM, META) Extracts metadata from DS.
% DIM may be 'row' or 'column', META is a string giving the field name
% to be extracted, or a cell array of strings giving the desired fields.
% If META is '_id' the corresponding row or column id is returned.
%
% METADATA = DS_GET_META(DS, DIM, META, IGNORE_MISSING) if IGNORE_MISSING
% is true, ignore missing fields.

% read string or numeric dim
dim_str = get_dim2d(dim);

% convert to cell array    
if ischar(meta)
    meta = {meta};
end
if nargin < 4
    ignore_missing = false;
end
% special field for extracting the ids
id_field = {'_id'};
if any(ismember(meta, id_field))
    get_id = true;
    meta = setdiff(meta, id_field);
else
    get_id = false;
end

switch(lower(dim_str))
    case 'row'
        isk = ds.rdict.isKey(meta);
        if ~all(isk) && ~ignore_missing
            bad = cellfun(@(x) sprintf('''%s''', x), meta(~isk), ...
                'UniformOutput', false);
            error('Bad row annotation field(s): %s\n', ...
                print_dlm_line(bad, 'dlm', ', '))
        end
        metadata = ds.rdesc(:, cell2mat(ds.rdict.values(meta(isk))));
        if get_id
            metadata = [ds.rid, metadata];
        end
    case 'column'
        isk = ds.cdict.isKey(meta);
        if ~all(isk) && ~ignore_missing
            bad = cellfun(@(x) sprintf('''%s''', x), meta(~isk), ...
                'UniformOutput', false);
            error('Bad column annotation field(s): %s\n', ...
                print_dlm_line(bad, 'dlm', ', '))
        end
        metadata = ds.cdesc(:, cell2mat(ds.cdict.values(meta(isk))));
        if get_id
            metadata = [ds.cid, metadata];
        end
    otherwise
        error('Dim should be ''row'' or ''column''')
end


% if all columns are numeric, convert from cell to numeric matrix
if ~isempty(metadata) && all(cellfun(@(x) isnumeric(x), metadata(1,:)))
    metadata = cell2mat(metadata);
elseif isempty(metadata)
    metadata = '';
end
