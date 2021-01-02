function s = mvfield(s, oldfield, newfield)
% MVFIELD Rename a field in a structure. 
%   NS = MVFIELD(S, OF, NF) Renames field OF to NF in structure S.

narginchk(3, 3);
assert(isstruct(s), 'S should be a structure');
assert(ischar(oldfield) | iscell(oldfield), 'oldfield should be a string or cell');
assert(ischar(newfield) | iscell(newfield), 'newfield should be a string or cell');

if ischar(oldfield)
    oldfield = {oldfield};
end

if ischar(newfield)
    newfield = {newfield};
end
nf = length(oldfield);
assert (isequal(nf, length(newfield)), 'length of oldfield and newfield must be the same');

field_order = fieldnames(s);
field_dict = mortar.containers.Dict(field_order);

for ii=1:nf
    assert(isfield(s, oldfield{ii}), 'field not found %s', ...
           oldfield{ii});
    if ~isequal(newfield{ii}, oldfield{ii})
        if isfield(s, newfield{ii})
            field_order{field_dict(newfield{ii})} = '';
            warning('mvfield:WarnOvewriteField', ['Overwriting field %s ' ...
                                'with %s'], newfield{ii}, oldfield{ii});
        end
        [s.(newfield{ii})] = s.(oldfield{ii});
        s = rmfield(s, oldfield{ii});
        field_order{field_dict(oldfield{ii})} = newfield{ii};
    else
        warning('mvfield:WarnMoveToSelf','Ignoring renaming field "%s" to itself', newfield{ii});
    end
end
field_order = field_order(~strcmp(field_order, ''));
s = orderfields(s, field_order);
end
