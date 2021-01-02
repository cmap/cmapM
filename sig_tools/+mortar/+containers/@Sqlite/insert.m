function result = insert(obj, table_name, table)
%Insert rows into a table from a structure

nrow = length(table);
fn = fieldnames(table);
id = mortar.legacy.print_dlm_line(lower(obj.validateName_(fn)), 'dlm', ',');
obj.run('BEGIN TRANSACTION');
try
    for ii=1:nrow
        vals = struct2cell(table(ii));
        dtype = cellfun(@class, vals,'uniformoutput', false);
        is_char_type = strcmp('char', dtype);
        vals(is_char_type) = strrep(vals(is_char_type),'"','""');
        vals(is_char_type) = mortar.legacy.quote(vals(is_char_type));
        val_str = mortar.legacy.print_dlm_line(vals, 'dlm',',', 'emptyval', '-666');
        obj.run(sprintf('INSERT INTO %s (%s) VALUES (%s)', table_name, id, val_str));
    end
catch exception
    obj.run('ROLLBACK');
    rethrow(exception);
end
result = obj.run('COMMIT');
end