function b_idx = lookup_fields(tbl_a, tbl_b, fields_a, fields_b)
% Lookup fields from tables
% Given two tables and a field mapping between the tables, lookup values
% from the second table corresponding to the fields in the first table.

if ischar(fields_a)
    fields_a = {fields_a};
end
if ischar(fields_b)
    fields_b = {fields_b};
end

nf_a = length(fields_a);
nf_b = length(fields_b);

assert(isequal(nf_a, nf_b), 'length of fields_a and fields_b should be the same')
assert(all(isfield(tbl_a, fields_a)), 'tbl_a must contain fields_a');
assert(all(isfield(tbl_b, fields_b)), 'tbl_a must contain fields_b');

nrec_a = length(tbl_a);
b_idx = nan(nrec_a, 1);
for ii=1:nf_a
    b2idx = mortar.containers.Dict({tbl_b.(fields_b{ii})});
    a_val = {tbl_a.(fields_a{ii})};
    this_match_idx = b2idx(a_val);
    is_miss_match = isnan(b_idx);
    b_idx(is_miss_match) = this_match_idx(is_miss_match);
end
end