function x = set_diagonal(x, val)
% SET_DIAGONAL Set diagonal elements of a square matrix
%   X = SET_DIAGONAL(X, V) Sets the diagonal elements of a sqare matrix X 
% to V.

[nr, nc] = size(x);
nv = length(val);
assert(isequal(nr,nc), 'Input must be square');
assert(isequal(nv, 1) || isequal(nv, nr),...
    'Val must be a scalar or vector of length(x)');
x(1:size(x,1)+1:end) = val;

end