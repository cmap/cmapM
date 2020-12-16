function R = pwcorr(X,Y)
% PWCORR Compute pairwise Pearson correlation
%
% R = PWCORR(X,Y) computes the pairwise Pearson corelation between
% corresponding columns of X and Y. Matrices X and Y should have the
% same dimensions. PWCORR returns the same values as diag(corr(X,Y))
% but is more efficient since it does not consider all pairs of
% columns of X and Y.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

if isequal (size(X), size(Y))
  N = size(X,1);
  R = sum(zscore(X).*zscore(Y))'/(N-1);
else
  error ('matrices must have the same dimensions')
end
