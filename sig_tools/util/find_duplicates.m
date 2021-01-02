function [dupval, dupidx, groupid] = find_duplicates(val)
% FIND_DUPLICATES find duplicates in a list.
% [DUPVAL, DUPIDX, GROUPID] = find_duplicates(V)

if isnumeric(val);
    val = num2cellstr(val);
end
% dict to store values and indices
m = containers.Map();
% dictionary of duplicate values and indices
dups = containers.Map();
num_vals = length(val);
for ii=1:num_vals
    % key exists so is a duplicate
    if m.isKey(val{ii})
        m(val{ii})=[m(val{ii}), ii];
        dups(val{ii})=m(val{ii});
    else
        m(val{ii}) = [ii];
    end
end

%%
if ~isempty(dups)
dv = dups.values;
% indices of duplicates in original list
dupidx = [dv{:}]';
% Group id and duplicate values
[groupid, dupval] = grp2idx(val(dupidx));

% group index
% number of duplicate groups
%numgroup = sum(cellfun(@length, dv));
else
    dupval = [];
    dupidx = [];
    groupid = [];
end
end
