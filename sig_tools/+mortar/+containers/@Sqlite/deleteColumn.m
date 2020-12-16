function result = deleteColumn(obj, table_name, columns)
% Delete columns from a table
assert(obj.istable(table_name), 'Invalid table name: %s', table_name);
if ischar(columns)
    columns = {columns};
end
is_col = obj.iscolumn(table_name, columns);
assert(all(is_col), 'Column(s) not found: %s', mortar.legacy.print_dlm_line(columns(~is_col)));
schema = obj.schema(table_name);
[~, idx] = setdiff({schema.name}, columns);
schema = schema(sort(idx));
keep_columns = lower(obj.validateName_({schema.name}));
keep_list = mortar.legacy.print_dlm_line(keep_columns, 'dlm', ', ');

% gen tmp table name
new_table = strcat(table_name,'_1');
is_good_name = ~obj.istable(new_table);
ctr = 2;
while ~is_good_name
    new_table = sprintf('%s_%d', table_name, ctr);
    is_good_name = ~obj.istable(new_table);
    ctr = ctr + 1;
end
% No column delete support in sqlite, so
% create a new table, copy keep_columns and delete the original
obj.run('BEGIN TRANSACTION');
try
    obj.run(sprintf('CREATE TABLE %s AS SELECT %s FROM %s', new_table, keep_list, table_name));
    obj.run(sprintf('DROP TABLE %s', table_name));
    obj.run(sprintf('ALTER TABLE %s RENAME TO %s', new_table, table_name));
catch exception
    obj.run('ROLLBACK');
    rethrow(exception);
end
result = obj.run('COMMIT');
end