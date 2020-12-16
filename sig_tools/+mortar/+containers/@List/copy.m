function new = copy(obj)
% Return a copy of the List object.
new = feval(class(obj));
new.data_ = obj.data_;
end