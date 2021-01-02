function tbl=tbl_fill_missing_value(tbl, val)
% TBL_FILL_MISSING_VALUE Fill missing values in a table with user specified
% value.
% T = TBL_FILL_MISSING_VALUE(T, V)

tbl = parse_record(tbl, 'detect_numeric', false);

fn = fieldnames(tbl);
nf = length(fn);
for ii=1:nf
    this_fn = {tbl.(fn{ii})}';
    ise = cellfun(@isempty, this_fn);
    dtype = class(this_fn(find(~ise, 1, 'first')));    
    tbl = setarrayfield(tbl, ise, fn{ii}, val);
end

end