function [z, mu, sigma] = robust_zscore(x, dim, varargin)
% ROBUST_ZSCORE Compute robust z-scores
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

[z, mu, sigma] = robust_zscore(x, dim, varargin{:});

end
