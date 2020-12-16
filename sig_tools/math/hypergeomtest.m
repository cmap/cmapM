% HYPERGEOMTEST Compute pdf for hypergeometric distribution.
% P = HYPERGEOMTEST(k, N, m, n) Computes the probability P of obtaining k
% from a hypergeometric distribution with parameters (N, m, n). 

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

% Perhaps the easiest way to understand this distribution is in terms of
% urn models. Suppose you are to draw "n" balls without replacement from an
% urn containing "N" balls in total, "m" of which are white. The
% hypergeometric distribution describes the distribution of the number of
% white balls drawn from the urn.
% See:
% http://en.wikipedia.org/wiki/Hypergeometric_distribution
%
% Numerical Recipes in C 
% [6.1 Gamma Function, Beta Function, Factorials, Binomial Coefficients]
% http://www.fizyka.umk.pl/nrbook/c6-1.pdf

function p = hypergeomtest(k,N,m,n)

% p = exp((factln(m) + factln(n) + factln(N - m) + factln(N-n)) - ...
%     (factln(k) + factln(m-k) + factln(N-m-n+k) + factln(N) + factln(n-k)));
p = exp(sum(factln([m, n, N-m, N-n])) -...
    sum(factln([k, m-k, N-m-n+k, N, n-k])));

% log Gamma function, gamma(x) = (x-1)!
function f = factln(x)
    f = gammaln(x+1);
