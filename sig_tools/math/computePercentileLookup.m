function [v, p] = computePercentileLookup(x, min_x, max_x, nbins)
% computePercentileLookup Compute lookup table for percentiles of a given
% measure
%   [V, P] = computePercentileLookup(X, MIN_X, MAX_X, NBINS)
% Computes percentiles for values of X interpolated over the range specified
% by MIN_X:MAX_X discretized into NBINS. The function returns V the range
% of X values and P the corresponding percentile values.

x = x(:);
min_val = min(x);
max_val = max(x);

if min_x > min_val
    dbg(1, 'Minimum in X is less than min_x, setting min_x to %f', min_val)
    min_x = min_val;
end

if max_x < max_val
    dbg(1, 'Maximum in X is greater than max_x, setting max_x to %f', max_val)
    max_x = max_val;
end

v = linspace(min_x, max_x, nbins);
% Clip x at min_x, max_x and compute fractions
[f0, v0] = cdfcalc(clip(x, min_x, max_x));

% interpolate over specified range and convert to percentiles
p = interp1(v0, 100*f0(1:end-1), v, 'nearest');

% Set NaNs to max
inan = isnan(p);
left_tail = find(~inan, 1, 'first');
right_tail = find(~inan, 1, 'last');
nan_idx = find(inan);
p(nan_idx(nan_idx <= left_tail)) = 0;
p(nan_idx(nan_idx >= right_tail)) = 100;

end