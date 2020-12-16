function result = schema(obj, table_name)
%Get schema of a table
result = obj.run(sprintf('PRAGMA table_info("%s")', table_name));
end
