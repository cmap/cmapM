function lx = safe_log2(x, minval)
% SAFE_LOG2 Base-2 logarithm ignoring negative and zero values.
%   Y = safe_log2(X) returns the base-2 log of X, thresholding the values
%   to a minimum of eps. Equivalent to Y = log2(max(X, eps)).
%
%   Y = safe_log2(X, MINVAL) sets the minimum value to MINVAL.
%
%   Example:
%   safe_log2([0,-1,2,3,4])
%   safe_log2([0,-1,2,3,4], 1)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

if ~exist('minval','var')
    minval = eps;
end
lx = log2(max(x, minval));
