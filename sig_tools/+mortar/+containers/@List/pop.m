function el = pop(obj)
% POP Delete the last element from a list and return it.

if ~obj.isempty
    el = obj.data_{end};
    obj.data_ = obj.data_(1:end-1);
else
    el = {};
end

end