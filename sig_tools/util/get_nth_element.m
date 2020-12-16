function x = get_nth_element(c, n, miss_val)
% GET_NTH_ELEMENT Select nth element from a cell array of variable length vectors.
% X = GET_NTH_ELEMENT(C, N) returns the Nth element for each row in C.
% Replaces missing values with -666.
% X = GET_NTH_ELEMENT(C, N, MISS_VAL) pads missing values with MISS_VAL

narginchk(2, 3)
if isequal(nargin, 2)
    miss_val = -666;
end

assert(iscell(c), 'C should be a cell array');
assert(n>0 && isequal(n, round(n)), 'N should be a positive integer');

len = cellfun(@length, c);
x = ones(size(c, 1),1) * miss_val;
isok = len >=n;
x(isok) = cellfun(@(x) x(n), c(isok));

end