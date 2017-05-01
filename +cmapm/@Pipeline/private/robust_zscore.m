function [z, mu, sigma] = robust_zscore(x, dim, varargin)
% ROBUST_ZSCORE Robust z score.
%
%   Z = ROBUST_ZSCORE(X) returns a centered, scaled version of matrix
%   X, the same dimensions as X. For vector input X, Z is the vector
%   of z-scores (X-MEDIAN(X)) ./ (MAD(X)*1.4826). For matrix X,
%   z-scores are computed using the median and MAD along each column
%   of X.  For higher-dimensional arrays, z-scores are computed using
%   the median and MAD along the first non-singleton dimension.
%
%   [Z,MU,SIGMA] = ROBUST_ZSCORE(X) also returns MEDIAN(X) in MU and
%   MAD(X) in SIGMA.
%
%   ROBUST_ZSCORE(X, DIM) Computes the z-score along dimension DIM
%   
%   ROBUST_ZSCORE(X, DIM, param, value, ...) Specify optional parameters:
%
%   'median_space': Vector of indices, estimate the median using specified
%                   indices.
%
%   'min_mad': Scalar, Minimum MAD value. Default is 0.1
%
%   'var_adjustment': String, Adjustment for low variance. Valid options are:
%
%                   'fixed': Use 'min_mad' for minimum variance.
%
%   See also ZSCORE, MEDIAN, MAD.

pnames = {'median_space', 'var_adjustment', 'min_mad'};
dflts = {[], 'fixed', 0.1};
args = parse_args(pnames, dflts, varargin{:});

if isequal(x,[]), z = []; return; end

if nargin < 2
    % Figure out which dimension to work along.
    dim = find(size(x) ~= 1, 1);
    if isempty(dim), dim = 1; end
end
if ~isempty(args.median_space)
    if isequal(dim, 1);
        v = x(args.median_space, :);
    else
        v = x(:, args.median_space);
    end    
    mu = nanmedian(v, dim);
    sigma = mad(v, 1, dim);
    
else
    mu = nanmedian(x, dim);
    sigma = mad(x, 1, dim);
end

% adjust for low variance
switch lower(args.var_adjustment)
    case 'fixed'
        min_mad = args.min_mad;
    otherwise
        error('Unknown variance adjustment method: %s', args.var_adjustment);
end
sigma0 = max(sigma, min_mad);
z = bsxfun(@rdivide, bsxfun(@minus, x, mu), sigma0 * 1.4826);
end
