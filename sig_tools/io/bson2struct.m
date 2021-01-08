function S = bson2struct(b)
% BSON2STRUCT converts a bson object to a MATLAB structure for convenience
%   S = BSON2STRUCT(B)
%   B is a bson object return from a cursor to a mongo query

% get the field names
fields = [];
it = b.iterator();
while it.next()
    fields = [fields; {it.key()}]; %#ok<AGROW>
end
nfields = length(fields);
S = struct();
for ii = 1:nfields
    f = fields{ii};
    if strcmp(f, '_id')
        continue
    end
    S.(f) = b.value(f);
end