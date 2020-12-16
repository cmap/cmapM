function p = phyper(k,w,b,n,varargin)
% PHYPER Compute the CDF for the hypergeometric distribution.
% P = PHYPER(k, w, b, n) Computes the probability P[X<=k] from a
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
% See also: DHYPER

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'-logp', '-lower_tail'};
dflts = {false, true};
arg = parse_args(pnames, dflts, varargin{:});

nk=length(k);
p = zeros(nk,1);


for ii=1:nk
    if arg.lower_tail
        st = 0;
        stp = k(ii);
    else
        st = min(k(ii)+1,n);
        stp = min(n,w);
    end
    p(ii) = sum(dhyper(st:stp, w, b, n, '-logp', false));
    if arg.logp
        p(ii) = log(p(ii));
    end
end
