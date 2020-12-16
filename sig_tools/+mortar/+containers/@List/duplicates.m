function [dup, dup_idx, freq] = duplicates(obj)
% Find duplicate elements in the list.
% [DUP, DUP_IDX, FREQ] = duplicates(obj)
%
dup = {};
dup_idx = [];
freq = [];
nout=nargout;
if ~obj.isempty
    dict = containers.Map(obj.data_, 1:obj.length);
    if ~isequal(obj.length, dict.Count)
        ind = ~ismember(1:obj.length, cell2mat(dict.values(dict.keys)));
        dup = obj.data_(ind);
        if nout>1
            % find indices
            ndup = length(dup);
            dup_idx = cell(ndup, 1);
            for ii=1:ndup
                dup_idx{ii} = find(cellfun(@(x) x==dup{ii}, obj.data_));
            end
        end
        if nout>2
            % counts
            freq = cellfun(@length, dup_idx);
        end
    end
end
end