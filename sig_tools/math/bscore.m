function [B, M, RE, CE, GE, RES] = bscore(X, min_mad)
% BSCORE Apply B-score procedure
% [B, M, RE, CE, GE, RES] = BSCORE(X, MIN_MAD) Applies Bscore procedure to
% a 2-d matrix X.

[RE, CE, GE, RES] = median_polish(X);
M = clip(mad(RES(:), 1), min_mad, inf);
B = RES / (1.4826 * M);

end