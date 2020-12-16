function col = columns(obj, table_name)
% Get column names in a table
col = {};
if mortar.legacy.isvarexist('table_name')
    assert(obj.istable(table_name), 'Table not found %s', table_name);
    result = obj.schema(table_name);
    if ~isempty(result)
        col = {result.name}';
    end
end
end