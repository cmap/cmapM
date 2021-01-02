function result = saveTable(obj, table_name, out_file)
% Save table to text file
if ischar(table_name)
    table_name = {table_name};
end
nt = length(table_name);
[p,f,e] = fileparts(out_file);
for ii=1:nt
    if obj.istable(table_name{ii})
        ofname = mortar.legacy.ifelse(nt>1, fullfile(p, sprintf('%s_%s%s', f, lower(table_name{ii}), e)), out_file);
        result = obj.run(sprintf('select * from %s', table_name{ii}));
        mortar.legacy.mktbl(ofname, result);
    end
end
end