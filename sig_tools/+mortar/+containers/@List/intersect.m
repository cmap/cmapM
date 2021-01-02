function [cmn, ia, ib] = intersect(obj, other, isordered)
% INTERSECT Find the set intersection of two lists.
%   C = listA.intersect(listB) returns the elements common to both lists A
%   and B. 
%
%   [C, IA, IB] = listA.intersect(listB) also returns index vectors
%   IA and IB such that C = listA(IA) and listB(IB).
%
%   [C, IA, IB] = listA.intersect(listB, ISORDERED) If ISORDERED is true,
%   returns elements in C ordered as in listB;
%
% See also INTERSECT

if nargin == 3 && isordered    
    listb = obj.parse_(other);    
    [cmn, ia, ib] = mortar.legacy.setop('mortar.legacy.intersect_ord', obj.data_, listb);
    obj.data_ = cmn;
    
elseif nargin >= 2    
    listb = obj.parse_(other);
    [cmn, ia, ib] = mortar.legacy.setop('intersect', obj.data_, listb);
    obj.data_ = cmn;
end
end
