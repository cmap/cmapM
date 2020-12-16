function [dup, dup_idx, freq] = FindDuplicate(list)
% find duplicates in a list
dup = {};
dup_idx = [];
freq = [];

n = length(list);
dict = containers.Map(list, 1:n);
if ~isequal(n, dict.Count)
    ind = ~ismember(1:n, cell2mat(dict.values(dict.keys)));
    dup = list(ind);
    if nargout>1
        % find indices
        ndup = length(dup);
        dup_idx = cell(ndup, 1);
        for ii=1:ndup
            dup_idx{ii} = find(cellfun(@(x) x==dup{ii}, list));
        end
    end
    if nargout>2
        % counts
        freq = cellfun(@length, dup_idx);
    end
end
end