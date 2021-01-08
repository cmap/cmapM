function [y, bidx] = discretize(x, bins)
% DISCRETIZE discretize values to specified bins
%   [Y, BIDX] = DISCRETIZE(X, BINS)

minb = min(bins);
maxb = max(bins);
x = clip(x, minb, maxb);
bidx = interp1(bins, 1:length(bins), x, 'nearest');
y = bins(bidx);
end