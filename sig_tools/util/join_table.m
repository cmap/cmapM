function tbl1 = join_table(tbl1, tbl2, tbl1_keyfield, tbl2_keyfield, select_fields, missing_val)
% JOIN_TABLE performs a left join of two tables
%
% T = JOIN_TABLE(T1, T2, T1KEY, T2KEY) joins table T1 with T2 on key fields
% T1KEY and T2KEY and returns table with the same content as T1 and all
% fields from T2
%
% T = JOIN_TABLE(T1, T2, T1KEY, T2KEY, T2FN) only returns fields T2FN from
% table T2
%
% T = JOIN_TABLE(T1, T2, T1KEY, T2KEY, T2FN, MISS_VAL) replaces missing
% values with MISS_VAL
    
tbl1 = parse_record(tbl1, 'detect_numeric', false);
tbl2 = parse_record(tbl2, 'detect_numeric', false);
if ~isvarexist('select_fields') || isempty(select_fields)
    select_fields = setdiff(fieldnames(tbl2), {tbl1_keyfield, tbl2_keyfield}, 'stable');
elseif ischar(select_fields)
    select_fields = {select_fields};
end
if ~isvarexist('missing_val')
    missing_val = '';
end

[tbl1_key, tbl1_keygp, tbl1_keyidx, ~, tbl1_keygp_sz] = ...
    get_groupvar(tbl1, fieldnames(tbl1), tbl1_keyfield);
[tbl2_key, tbl2_keygp, tbl2_keyidx, ~, tbl2_keygp_sz] = ...
    get_groupvar(tbl2, fieldnames(tbl2), tbl2_keyfield);

tbl2_dup = duplicates(tbl2_key);
tbl2_has_dup = ~isempty(tbl2_dup);
assert(~tbl2_has_dup, 'Table2 has duplicate key field entries');
key_lut = mortar.containers.Dict(tbl2_key);
tbl2_idx = key_lut(tbl1_key);
isk = ~isnan(tbl2_idx);

nf = length(select_fields);
for ii=1:nf
    this_val = {tbl2(tbl2_idx(isk)).(select_fields{ii})};
    tbl1 = setarrayfield(tbl1, isk, select_fields{ii},...
        this_val);
    if ~isempty(missing_val)
        tbl1 = setarrayfield(tbl1, ~isk, select_fields{ii},...
            {missing_val});
    end
end

end