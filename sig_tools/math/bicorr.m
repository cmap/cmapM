function bc = bicorr(x, y)
% BICORR Calculate biweight midcorrelation.

bc = bicov(x, y) / (sqrt(bicov(x, x)*bicov(y, y)));
