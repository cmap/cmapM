function m = nisnan(x, dim)
%NISNAN Number of NaN elements in a matrix.
%   M = NISNAN(X) returns the NaNs in each column of X. For vector input, M
%   is the number of non-NaN elements in X.  For matrix input, M is
%   a row vector containing the number of NaN elements in each
%   column.  For N-D arrays, NISNAN operates along the first non-singleton
%   dimension.
%
%   NISNAN(X, DIM) counts the elements along dimension DIM of X.
%
%   See also MEAN, NANMEDIAN, NANSTD, NANVAR, NANMIN, NANMAX, NANSUM.


if nargin == 1 % let sum deal with figuring out which dimension to use
    % Count up NaNs.
    m = sum(isnan(x));
else   
    m = sum(isnan(x), dim);
end
