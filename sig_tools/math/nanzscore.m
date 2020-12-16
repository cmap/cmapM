function [zs, mu, sigma] = nanzscore(x,flag,dim)
% NANZSCORE Compute standardized z score ignoring NaNs
% Z = NANZSCORE(X) returns the z-scores computed using the mean and
% standard deviation along each column of X ignoring NaNs.
% [] is a special case for std and mean, just handle it out here.

if isequal(x,[]), zs = x; return; end

if nargin < 2
    flag = 0;
end
if nargin < 3
    % Figure out which dimension to work along.
    dim = find(size(x) ~= 1, 1);
    if isempty(dim), dim = 1; end
end

mu = nanmean(x, dim);
sigma = nanstd(x, flag, dim);
zs = bsxfun(@rdivide, bsxfun(@minus, x, mu), sigma);

end