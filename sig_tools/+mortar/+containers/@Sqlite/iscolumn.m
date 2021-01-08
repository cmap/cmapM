function yn = iscolumn(obj, table_name, columns)
% Check if column(s) exist in a table
assert(obj.istable(table_name), 'Table not found: %s', table_name);
columns = mortar.containers.Sqlite.toCell_(columns);
yn = false(length(columns), 1);
[~, ~, idx] = mortar.legacy.intersect_ord(obj.columns(table_name), columns);
yn(idx) = true;
end