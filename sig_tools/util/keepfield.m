function s = keepfield(s, fields)
% KEEPFIELD Select a subset of fields from a structure
% S = KEEPFIELD(S, FN) Filters structure S to retain fields in the same 
% order as FN. In case a field is missing, it is inserted with empty values
% into the structure.

narginchk(2, 2);
assert(isstruct(s), 'S should be a structure');
assert(ischar(fields) | iscell(fields), 'fields should be a string or cell');

if ischar(fields)
    fields = {fields};
end

fn = fieldnames(s);
s = rmfield(s, setdiff(fn, fields));

miss_field = setdiff(fields, fieldnames(s), 'stable');
if ~isempty(miss_field)
    miss_val = repmat({''}, length(miss_field), 1);
    s = setarrayfield(s, [], miss_field, miss_val{:});
end

s = orderfields(s, orderas(fieldnames(s), fields));

end