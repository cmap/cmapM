function [sd, ia] = setdiff(obj, other)
% Set difference

if nargin>1
    [sd, ia] = mortar.legacy.setop('setdiff', obj.data_, obj.parse_(other));
    obj.data_ = sd;
end

end