function ds = deannotate_ds(ds, dim)
% DEANNOTATE_DS Remove annotations from a dataset.
%   OUT = DEANNOTATE_DS(DS) returns dataset DS with both row and column
% annotations removed.
%   OUT = DEANNOTATE_DS(DS, DIM) Deletes annotations from the specified
% dimension DIM, which can be {'row', 'column', 'both'}.

if ~isvarexist('dim')
    dim = 'both';
end

assert(ischar(dim), 'Unsupported dimension expected string');

switch (lower(dim))
    case 'row'
        ds = ds_delete_meta(ds, 'row', ds.rhd);
    case 'column'
        ds = ds_delete_meta(ds, 'column', ds.chd);
    case 'both'
        ds = ds_delete_meta(ds, 'row', ds.rhd);
        ds = ds_delete_meta(ds, 'column', ds.chd);
    otherwise
        error('Unsupported dimension %s, expected {row, column, both}', dim)
end

end


