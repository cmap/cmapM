function index = inverted_index(k, v)
% LIST2DICT Create a dictionary.
% D = LIST2DICT(K)
% D = LIST2DICT(K, V)
if isempty(k)
    index = containers.Map();
else
    
    if ~iscell(k) || ~isequal(numel(k), length(k))
        error('Input should be a 1D cell array')
    end
    
    if ~isdefined('v')
        v = 1:length(k);
    end
    
    % first ignore dups
    index = containers.Map('KeyType', 'char', 'ValueType', 'any');
    [dup, dupidx, gp] = duplicates(k);
    if ~isempty(dup)
        for ii=1:length(dup)
            index(dup{ii}) = dupidx(gp==ii);
        end
    end
    
end
end