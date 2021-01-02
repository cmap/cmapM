function [hc, hh] = plot_cdfhist(y, bins)
% PLOT_CDFHIST Display empirical cumulative distribution and histogram
%   [HC, HH] = PLOT_CDFHIST(Y, BINS)

y = y(:);
npoints = length(y);
if verLessThan('matlab', '9.0')
    hh = plot_norm_hist(y, bins, 'type', 'relfreq');    
    hold on
    [yy, xx] = cdfcalc(y);
    k = length(xx);
    n = reshape(repmat(1:k, 2, 1), 2*k, 1);
    xCDF = [-Inf; xx(n); Inf];
    yCDF = [0; 0; yy(1+n)];
    hc = plot(xCDF, yCDF);
else
    % TOFIX: grid corresponds to left axis but prefer it matches the CDF on the
    % right. Note with yyaxis grid aligned to right is not currently supported    
    yyaxis left
    hh = plot_norm_hist(y, bins, 'type', 'relfreq');    
    yyaxis right
    hc = cdfplot(y);
end
axis tight
title(sprintf('n=%d', npoints));

end