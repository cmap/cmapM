function tf = eq(obj, obj2)
% EQ Test two lists for equality.

if ~isa(obj2, class(obj))
    obj2 = feval(class(obj), obj2);
end

tf = false;
if isequal(obj.length, obj2.length)
    if obj.length == 0
        tf = true;
    elseif mortar.legacy.iscellnum(obj.data_)
        tf = obj.data_ == obj2.data_;
    else
        tf = strcmp(obj.data_, obj2.data_);
    end
end
end