function unmark(fname, id)
% Remove id from mark file
assert(isdefined('fname') && ischar(fname), 'filename not specified');
assert(isdefined('id') && ischar(id), 'id not specified');

if isfileexist(fname)
    tbl = parse_tbl(fname, 'outfmt', 'record', 'verbose', false);
    idx = strcmp(id, {tbl.id});
    if any(idx)
        % id exists, delete it
        tbl(idx) = [];
        if ~isempty(tbl)
            mktbl(fname, tbl, 'verbose', false);
            dbg(1, 'Updated %s', fname);
        else
            delete(fname)
        end
        
    end
end

