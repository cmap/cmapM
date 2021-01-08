function x = clip(x, lo, hi)
% CLIP Threshold values
% Y = CLIP(X, LO, HI) Thresholds X so that values >= HI are set to HI and
% values <= LO are set to LO.

inan = isnan(x);
x = max(min(x, hi), lo);
x(inan) = nan;

end