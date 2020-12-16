function p = dhyper(k,w,b,n,varargin)
% DHYPER Compute density for hypergeometric distribution.
% P = DHYPER(k, N, m, n) Computes the probability P of obtaining k from a
% hypergeometric distribution with parameters (w, b, n). Perhaps the
% easiest way to understand this distribution is in terms of urn models.
% Suppose you are to draw "n" balls _without_ replacement from an urn
% containing "w" white balls and "b" black balls. The hypergeometric
% distribution describes the distribution of the number of white balls
% drawn from the urn.
%
% P = PHYPER(k, w, b, n, '-logp', false, '-lower_tail', true) 
%   '-logp' : boolean; if true reports log probabilities
%   '-lower_tail' : boolean; if true(default) probabilities are P[X<=k],
%   otherwise, P[X>k]
%
% Reference:
% [1] http://en.wikipedia.org/wiki/Hypergeometric_distribution
% [2] Gamma Function, Beta Function, Factorials, Binomial Coefficients,
% Numerical Recipes in C, http://www.fizyka.umk.pl/nrbook/c6-1.pdf
%
% See also: PHYPER

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

pnames = {'-logp'};
dflts = {false};
arg = parse_args(pnames, dflts, varargin{:});

% log Gamma function to compute factorials. Note: gamma(x) = (x-1)!
% factln = @(x) gammaln(x+1);
N = w+b;
nk = length(k);
p = zeros(nk,1);
for ii=1:nk
    p(ii) = sum(factln([w, n, b, N-n])) -...
        sum(factln([k(ii), w-k(ii), b-n+k(ii), N, n-k(ii)]));
    if ~arg.logp
        p(ii) = exp(p(ii));
    end
end
