function [c, ia, ib] = setxor(obj, other)
% Find exclusive OR of two vectors

if nargin>1
    [c, ia, ib] = mortar.legacy.setop(@setxor, obj.data_, obj.parse_(other));
    obj.data_ = c;
end

end