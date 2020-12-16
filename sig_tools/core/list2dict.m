function d = list2dict(k, v)
% LIST2DICT Create a dictionary.
% D = LIST2DICT(K)
% D = LIST2DICT(K, V)
if isempty(k)
    d = containers.Map();
else
    
    if ~iscell(k) || ~isequal(numel(k), length(k))
        error('Input should be a 1D cell array')
    end
    if ~isequal(length(k), length(unique(k)))
        fprintf ('Duplicate keys:\n');
        disp(finddup(k))
        error('Keys should be unique')
    end
    
    if ~isdefined('v')
        v = 1:length(k);
    end
    d = containers.Map(k, v);
end
end