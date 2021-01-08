function x = cliptonan(x, lo, hi)
% CLIPTONAN Threshold values to NaN
% Y = CLIPTONAN(X, LO, HI) Thresholds X so that values >= HI and
% values <= LO are set to NaN.

x(x<lo) = nan;
x(x>hi) = nan;

end