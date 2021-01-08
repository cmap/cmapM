function mark(fname, id)
% Add entry to mark file
assert(isdefined('fname') && ischar(fname), 'filename not specified');
assert(isdefined('id') && ischar(id), 'id not specified');

if isfileexist(fname)
    tbl = parse_tbl(fname, 'outfmt', 'record', 'verbose', false);
else
    tbl = struct('id', id, 'timestamp', '');
end
idx = strcmp(id, {tbl.id});
ts = datestr(now);
if any(idx)
    % id exists, update time stamp
    tbl(idx).timestamp = ts;
else
    % append id and timestamp
    idx = length(tbl)+1;
    tbl(idx).id = id;
    tbl(idx).timestamp = ts;
end
% sort by timestamp
[~, ord] = sort(datenum({tbl.timestamp}), 'descend');
tbl = tbl(ord);

mktbl(fname, tbl, 'verbose', false);
dbg(1, 'Updated %s', fname);
