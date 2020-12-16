function idx =  max_index(x, varargin)
% MAX_INDEX Index of largest value.
%   I = MAX_INDEX(X) returns the index of the maximum of X ignoring NaNs.
%       For vectors, I is the index of the largest non-NaN element in X.
%       For matrices, M is a row vector containing the maximum non-NaN
%       element from each column. For N-D arrays, nanmax operates along the
%       first non-singleton dimension.
%
%   I = MAX_INDEX(X, Y) returns an array the same size as X and Y with the
%       largest elements taken from X or Y.  Either one can be a scalar.
%
%   I = MAX_INDEX(X, [], DIM) operates along dimension DIM.
% 

nin = nargin;
if nin>1
   y = varargin{1};
else
    y = [];
end
if nin>2
    dim = varargin{2};
elseif isvector(x)
    [~, dim] = max(size(x));
else
    dim = 1;
end
    
[~, idx] = nanmax(x, y, dim);

end