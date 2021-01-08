function result = create(obj, table_name, table, primary_key, populate)
%Create a new table
%             assert(obj.isvalidTableName_(table_name), 'Invalid table name:%s', table_name)
table_name = mortar.containers.Sqlite.validateTableName_(table_name);
schema = obj.structToSchema_(table, primary_key);
sql = obj.schemaToSql_(table_name, schema);
obj.run('BEGIN TRANSACTION');
try
    result = obj.run(sql);
catch e
    obj.run('ROLLBACK');
    rethrow(e);
end
obj.run('COMMIT');
if populate
    obj.insert(table_name, table);
end
end