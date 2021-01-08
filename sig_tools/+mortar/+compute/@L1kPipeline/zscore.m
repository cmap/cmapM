function [z, mu, sigma] = zscore(x, dim, varargin)
% ZSCORE z-score a matrix 
%   Z = ZSCORE(X) returns z-scored verion X, the same size as X. Z is a
%   scaled and centered version of X. Two methods for computing Z-scores
%   are currently supported. The default is to compute a robust z-score as:
%   (X-NANMEDIAN(X)) ./ (MAD(X)*1.4826). Alternatively a standard zscore
%   can be specified and is computed as: (X-NANMEAN(X)) ./ NANSTD(X). In
%   addition adjustments are made to account for low variance as described
%   below.
%
%   For matrix X, z-scores are computed using the location and scale
%   parameters along each column of X.  For higher-dimensional arrays,
%   z-scores are computed using the median and MAD along the first
%   non-singleton dimension.
%
%   [Z,MU,SIGMA] = ZSCORE(X) also returns MEDIAN(X) in MU and MAD(X)
%   in SIGMA.
%
%   ZSCORE(X, DIM) Computes the z-score along dimension DIM
%   
%   ZSCORE(X, DIM, param, value, ...) Specify optional parameters:
%
%   'bkg_space': Vector of indices, estimate the median using specified
%                   indices.
%
%   'min_var': Scalar, Minimum MAD value. 
%
%   'var_adjustment': String, Adjustment for low variance. Valid options
%                     are:
%
%                   'estimate': The default method. Estimate the minimum
%                   variance from the data. EST_MAD = PRCTILE(SIGMA,
%                   est_prct), where SIGMA is a vector of MAD computed
%                   along dim for the entire dataset. The minimum variance
%                   is set to: MAX(EST_MAD, MIN_MAD).
%
%                   'fixed': Use 'min_mad' for minimum variance.
%
%                   'none': Assume min_mad is zero.
%
%   'estimate_prct': Scalar, Percentile to consider when estimating the
%                   minimum variance from the data. The default is 1.
%
%   'zscore_method': String, Method to use for computing z-score. Options are:
%               'robust' : Estimate robust zscores using median and MAD
%               'standard' : Estimate standad zscored using mean and std.


pnames = {'bkg_space', 'var_adjustment', 'min_var',...
          'estimate_prct', 'zscore_method'};
dflts = {[], 'estimate', eps,...
          1, 'robust'};
args = parse_args(pnames, dflts, varargin{:});

if isequal(x,[]), z = []; return; end

if nargin < 2
    % Figure out which dimension to work along.
    dim = find(size(x) ~= 1, 1);
    if isempty(dim), dim = 1; end
end

switch args.zscore_method
    case 'robust'
        mufn = @nanmedian;
        sigmafn = @(x, dim) mad(x, 1, dim);
    case 'standard'
        mufn = @nanmean;
        sigmafn = @(x, dim) nanstd(x, 0 , dim);
    otherwise
        error('Unknown z-score method %s, expected robust or standard',...
            args.zscore_method);
end

if ~isempty(args.bkg_space)
    if isequal(dim, 1)
        v = x(args.bkg_space, :);
    else
        v = x(:, args.bkg_space);
    end    
    mu = mufn(v, dim);
    sigma = sigmafn(v, dim);    
else
    mu = mufn(x, dim);
    sigma = sigmafn(x, dim);
end

% adjust for low variance
switch lower(args.var_adjustment)
    case 'estimate'
        min_var = max(prctile(sigma(:), args.estimate_prct), args.min_var);        
    case 'fixed'
        min_var = args.min_var;
    case 'none'
        min_var = 0;
    otherwise
        error('Unknown variance adjustment method: %s', args.var_adjustment);
end
sigma0 = max(sigma, min_var);
switch args.zscore_method
    case 'robust'
        z = bsxfun(@rdivide, bsxfun(@minus, x, mu), sigma0 * 1.4826);
    case 'standard'
        z = bsxfun(@rdivide, bsxfun(@minus, x, mu), sigma0);
    otherwise
        error('Unsupported z-score-method: %s', args.zscore_method);
end

end