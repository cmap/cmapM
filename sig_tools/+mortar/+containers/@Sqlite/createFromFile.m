function result = createFromFile(obj, table_name, file_name, primary_key)
%Create a new table from a text file
assert(~obj.istable(table_name), 'Table exists: %s', table_name);
table_name = mortar.containers.Sqlite.validateTableName_(table_name);
%             assert(obj.isvalidTableName_(table_name), 'Invalid table name:%s', table_name)
table = mortar.legacy.parse_tbl(file_name, 'outfmt', 'record');
assert(isfield(table, primary_key), 'Primary key %s not found', primary_key);
result = obj.create(table_name, table, primary_key, true);
end