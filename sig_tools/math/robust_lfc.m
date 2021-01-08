function [lfc, mu] = robust_lfc(x, dim, varargin)
% ROBUST_LFC Robust log fold change
%   L = ROBUST_LFC(X) returns X, the same size as X. For vector input X, L
%   is the vector of log-fold changes (X-MEDIAN(X)). For matrix X, log-fold
%   changes are computed using the median along each column of X.  For
%   2-dimensional arrays, fold changes are computed using the median along
%   the first non-singleton dimension.
%
%   [L, MU] = ROBUST_LFC(X) also returns MEDIAN(X) in MU 
%
%   ROBUST_LFC(X, DIM) Computes the fold changes along dimension DIM
%   
%   ROBUST_LFC(X, DIM, param, value, ...) Specify optional parameters:
%
%   'median_space': Vector of indices, estimate the median using specified
%                   indices.
%
%   See also ROBUST_ZSCORE

pnames = {'median_space'};
dflts = {[]};
args = parse_args(pnames, dflts, varargin{:});

if isequal(x,[]), lfc = []; return; end

if nargin < 2
    % Figure out which dimension to work along.
    dim = find(size(x) ~= 1, 1);
    if isempty(dim), dim = 1; end
end
if ~isempty(args.median_space)
    if isequal(dim, 1)
        v = x(args.median_space, :);
    else
        v = x(:, args.median_space);
    end    
    mu = nanmedian(v, dim);    
else
    mu = nanmedian(x, dim);
end

lfc = bsxfun(@minus, x, mu);
end