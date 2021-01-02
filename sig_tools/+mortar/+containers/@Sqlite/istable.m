function yn = istable(obj, table_name)
%Check if table(s) exists
table_name = mortar.containers.Sqlite.toCell_(table_name);
yn = false(length(table_name), 1);
[~, ~, idx] = mortar.legacy.intersect_ord(lower(obj.tables), lower(table_name));
yn(idx) = true;
end

