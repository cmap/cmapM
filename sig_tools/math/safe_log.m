function lx = safe_log(x, minval)
% SAFE_LOG Natural logarithm ignoring negative and zero values.
%   Y = safe_log(X) returns the natural log of X, thresholding the values
%   to a minimum of eps. Equivalent to Y = log(max(X, eps)).
%
%   Y = safe_log(X, MINVAL) sets the minimum value to MINVAL.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

if ~exist('minval','var')
    minval = eps;
end
lx = log(max(x, minval));
