function [uni, ia, ib] = union(obj, other)
% UNION Find the set union of two lists.
%   U = listA.union(listB)
%   [U, IA, IB] = listA.union(listB)
%
%   See also: UNION

if nargin>1
    [uni, ia, ib] = mortar.legacy.setop('union', obj.data_, obj.parse_(other));
    obj.data_ = uni;
end
end