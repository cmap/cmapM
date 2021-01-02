function result = addColumn(obj, table_name, columns)
% Add columns to a table
assert(obj.istable(table_name), 'Invalid table name: %s', table_name);
if ischar(columns)
    columns = {columns};
end
obj.run('BEGIN TRANSACTION');
try
    for ii=1:length(columns)
        obj.run(sprintf('ALTER TABLE %s ADD COLUMN %s', table_name, columns{ii}));
    end
catch exception
    obj.run('ROLLBACK');
    rethrow(exception);
end
result = obj.run('COMMIT');
end