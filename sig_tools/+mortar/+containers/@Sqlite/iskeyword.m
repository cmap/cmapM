function yn = iskeyword(s)
%Check if string is an SQL reserved word
yn = mortar.containers.Sqlite.keywords.isKey(upper(s));
end