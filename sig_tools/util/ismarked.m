function [yn, ts] = ismarked(fname, id)
% check if id exists in mark file

assert(isdefined('fname') && ischar(fname), 'filename invalid');
assert(isdefined('id') && ischar(id), 'id not specified');
yn = false;
ts = '';
if isfileexist(fname)
    tbl = parse_tbl(fname, 'outfmt', 'record', 'verbose', false);
    idx = strcmp(id, {tbl.id});
    yn = any(idx);
    if yn
        ts = tbl(idx).timestamp;
    end  
end
