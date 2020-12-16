function m = nisnotnan(x, dim)
%NISNOTNAN Number of non-NaN elements in a matrix.
%   M = NISNOTNAN(X) returns the number of non-NaNs in each column of X.
%   For vector input, M is the number of non-NaN elements in X.
%   For matrix input, M is a row vector containing the number of non-NaN
%   elements in each column.  For N-D arrays, NISNAN operates along the
%   first non-singleton dimension.
%
%   NISNOTNAN(X, DIM) counts the elements along dimension DIM of X.
%
%   See also MEAN, NANMEDIAN, NANSTD, NANVAR, NANMIN, NANMAX, NANSUM.

if nargin == 1 % let sum deal with figuring out which dimension to use
    % Count up non-NaNs.
    m = sum(~isnan(x));
else   
    m = sum(~isnan(x), dim);
end
