function idx = index(obj, el)
% Returns indices of items matching a given element.

cls = class(el);
if strcmp(cls, 'char')
    idx = find(strcmp(el, obj.data_));
elseif ismember(cls, mortar.legacy.numeric_type)
    idx = find(cellfun(@(x) x==el, obj.data_));
end

end