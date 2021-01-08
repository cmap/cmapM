function [x, y] = gencorr2d(n, r)
% GENCORR2D Generate correlated vectors.
% [X, Y] = GENCORR2D(N, R) Generates vectors X and Y of length N, whose
% correlation is R.
r = r(:);
% pseudo random variables
v = randn(n, 2);
% uncorrelated variables
[~, scores] = princomp(v);
x = scores(:, 1);
y = x*r' + scores(:, 2) * sqrt(1 - r.^2)';

end