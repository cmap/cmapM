function table_name = validateTableName_(table_name)
% Validate a table name
if mortar.containers.Sqlite.keywords.isKey(upper(table_name))
    % quote if table name is a keyword
    table_name = mortar.containers.Sqlite.keywords(upper(table_name));
elseif ~mortar.containers.Sqlite.isvalidTableName_(table_name)
    error('Invalid table name: %s', table_name);
end
end
