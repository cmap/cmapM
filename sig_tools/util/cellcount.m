function [u, count, groupids] = cellcount(inpt, group)

    % CELLCOUNT count the frequency of elements in a cell array
    % [u, count] = CELLCOUNT(CELLARRAY) - returns a vector of the unique
    % elements of cell array (u) and a vector of their count in CELLARRAY
    % (count)
    %
    % [u, count, groupids] = cellcount(inpt, group) - if group if true,
    % returns a cell array of the indices in inpt for each unique element
    % (u), i.e. inpt(groupids{k}) = u{k}
    
    if nargin == 1
        group = 1;
        groupids = {};
    end
    
    if iscell(inpt) && or(isnumeric(inpt{1}), islogical(inpt{1}))
        inpt = double(cell2mat(inpt));
    end

    if isnumeric(inpt)
        u = unique(inpt);
        count = zeros(size(u));
        groupids = cell(size(u));
        
        for k = 1:numel(u)
            count(k) = sum(inpt == u(k));
            if group
                groupids{k} = find(inpt == u(k));
            end
        end
    else
        u = unique(inpt);
        umap = containers.Map();
        for i = 1:numel(u)
            umap(u{i}) = i;
        end

        if ~group
            count = zeros(numel(u), 1);
            for k = 1:numel(inpt)
                count(umap(inpt{k})) = count(umap(inpt{k})) + 1;
            end
        else
            groupids = cell(size(u));
            for k = 1:numel(inpt)
                groupids{umap(inpt{k})} = vertcat(groupids{umap(inpt{k})}, k);
            end

            count = cellfun(@(x) numel(x), groupids);
        end
    end
end
