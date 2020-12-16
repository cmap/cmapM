function p = q75(x, varargin)
% Q75 The 75th percentile of a sample.
%   P = Q75(X) returns the 75th percentile of X. When X is a vector P is a
%   scalar, when X is a matrix P is a row vector containing the 75th
%   percentiles of each column of X.

if nargin<2
    dim = 1;
else
    dim = varargin{1};
end

p = prctile(x, 75, dim);

end