function res = parse_jenkins_prop(prop_file)
% PARSE_JENKINS_PROP Parse Jenkins properties file

lines = parse_grp(prop_file);
nline = length(lines);
key = cell(nline, 1);
val = cell(nline, 1);
for ii=1:nline
% tokenize by =
kv = deblank(textscan(lines{ii}, '%s', 2, 'delimiter', '='));
key{ii} = kv{1}{1};
v = textscan(kv{1}{2}, '%s', inf, 'delimiter', ',');
val{ii} = v{1};
end
res = cell2struct(val, key, 1);
end