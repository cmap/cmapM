function rpt = tbl_diff(tbl1, tbl2, key1, key2, field1, field2)
% DIFF_TABLE compare two tables and report differences
% diff_table(tbl1, tbl2, key1, key2, field1, field2)

assert(all(isfield(tbl1, {key1, field1})),...
    'Table-1 does not contain %s or %s', key1, field1);
assert(all(isfield(tbl2, {key2, field2})),...
    'Table-2 does not contain %s or %s', key2, field2);

key1_val = {tbl1.(key1)}';
key2_val = {tbl2.(key2)}';

field1_val = {tbl1.(field1)}';
field2_val = {tbl2.(field2)}';

[cn1, nl1] = getcls(key1_val);
[cn2, nl2] = getcls(key2_val);

% tbl1 vs tbl2
% for each unique key1 value check if key2 exists
key1_lut = list2dict(cn1);
key2_lut = list2dict(cn2);

nk1 = length(key1_lut);
rpt1 = struct('key', cn1,...
              'diff', '',...
              'table1_val', '',...
              'table2_val', '',...
              'union', '',...
              'table_a', 'table1');
dbg(1, 'Comparing Table-1 vs Table-2 for %d keys', nk1);
for ii=1:nk1
    this1 = nl1 == ii;
    if key2_lut.isKey(cn1{ii})
        this2 = nl2==key2_lut(cn1{ii});
        this_val1 = field1_val(this1);
        this_val2 = field2_val(this2);
        % symmetric_difference: values not in the intersection
        diff_val = setxor(this_val1, this_val2);       
        rpt1(ii).diff = diff_val;
        rpt1(ii).table1_val = this_val1;
        rpt1(ii).table2_val = this_val2;
        rpt1(ii).union = union(this_val1, this_val2);
    end
end

% keys in tbl2 not in tbl1

cn2only = setdiff(cn2, cn1);
nk2 = length(cn2only);
rpt2 = struct('key', cn2only,...
              'diff', '',...
              'table1_val', '',...
              'table2_val', '',...
              'union', '',...
              'table_a', 'table2');
dbg(1, 'Examining Table-2 for %d keys not in Table-1', nk2);          
for ii=1:nk2
    this_key_index = key2_lut(cn2only{ii});
    dbg(1, '%d:%s', ii, cn2only{ii});
    this2 = nl2 == this_key_index;
    this_val1 = '';
    this_val2 = field2_val(this2);
    % symmetric_difference: values not in the intersection
    diff_val = setxor(this_val1, this_val2);
    rpt2(ii).diff = diff_val;
    rpt2(ii).table1_val = this_val1;
    rpt2(ii).table2_val = this_val2;
    rpt2(ii).union = union(this_val1, this_val2);
end
rpt = [rpt1;rpt2];
rpt = rpt(~cellfun(@isempty, {rpt.diff}'));


end