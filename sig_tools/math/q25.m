function p = q25(x, varargin)
% Q25 The 25th percentile of a sample.
%   P = Q25(X) returns the 25th percentile of X. When X is a vector P is a
%   scalar, when X is a matrix P is a row vector containing the 25th
%   percentiles of each column of X.

if nargin<2
    dim = 1;
else
    dim = varargin{1};
end
    
p = prctile(x, 25, dim);

end