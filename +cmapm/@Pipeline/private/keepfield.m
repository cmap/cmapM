function s = keepfield(s, fields)
% KEEPFIELD Select a subset of fields from a structure

narginchk(2, 2);
assert(isstruct(s), 'S should be a structure');
assert(ischar(fields) | iscell(fields), 'fields should be a string or cell');

if ischar(fields)
    fields = {fields};
end

fn = fieldnames(s);
s = rmfield(s, setdiff(fn, fields));
s = orderfields(s, orderas(fieldnames(s), fields));

end