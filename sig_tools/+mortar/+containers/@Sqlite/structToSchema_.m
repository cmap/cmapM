function schema = structToSchema_(obj, table_struct, primary_key)
%Infer SQL schema from matlab structure
fn = fieldnames(table_struct);
nf = length(fn);
dtype = cell(nf, 1);
pk = num2cell(strcmp(primary_key, fn));
for ii=1:nf
    dtype{ii} = obj.getSqliteType_(class(table_struct(1).(fn{ii})));
end
schema = struct('cid', 0:nf, ...
    'name', fn, ...
    'type', dtype,...
    'notnull', 0,...
    'dflt_value', [],...
    'pk', pk);
end