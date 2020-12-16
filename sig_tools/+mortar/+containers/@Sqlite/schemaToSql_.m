function sql = schemaToSql_(obj, table_name, schema)
%Construct SQL string from schema
nf = length(schema);
valid_fn = lower(obj.validateName_({schema.name}));
% primary key
pk = cell(1, nf);
pk([schema.pk]) = {'PRIMARY KEY'};

% end of line character
eol = cell(1, nf);
eol(1:nf-1) = {','};
s = mortar.legacy.print_dlm_line([valid_fn;{schema.type};pk;eol], 'dlm', ' ');
sql = sprintf('CREATE TABLE %s(%s)', table_name, s);
end