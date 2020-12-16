function [c, idx] = subset(a, b, invert)
% SUBSET Select a subset of elements from a set.
%   [C, IDX] = SUBSET(A, B) returns the elements in A that are common to B.
%   IDX is an array of indices of A such that C = A(IDX).
%   [C, IDX] = SUBSET(A, B, INVERT) returns the set difference of A and B
%   if INVERT is true. Default is false.

narginchk(2, 3)
if nargin < 3
    invert = false;
end
assert(islogical(invert));

if invert
    [c, idx] = setdiff(a, b);
else
    [c, idx] = intersect_ord(a, b);
end

end