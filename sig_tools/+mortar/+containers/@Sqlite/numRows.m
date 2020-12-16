function n = numRows(obj, table_name)
% Get number of rows in a table
n = 0;
if mortar.legacy.isvarexist('table_name')
    assert(obj.istable(table_name), 'Table not found %s', table_name);
    result = obj.run(sprintf('SELECT COUNT(*) FROM [%s]', table_name));
    if ~isempty(result)
        n = result.('COUNT(_)');
    end
else
    error('Table name not specified');
end
end
