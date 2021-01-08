function result = drop(obj, table_name)
% Delete a table
if ischar(table_name)
    table_name = {table_name};
end
for ii=1:length(table_name)
    if obj.istable(table_name{ii})
        result = obj.run(sprintf('DROP TABLE %s', table_name{ii}));
    end
end
end