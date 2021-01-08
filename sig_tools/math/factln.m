% FACTLN Compute log factorial.
% FACTLN(N) for an integer N, is the logarithm of the product of all the
% integers from 1 to N, i.e. log(prod(1:N))
% Note the log gamma function is used to compute the factorial without
% explicitly evaluating the product.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function fln = factln(x)

if all(isint(x))
    fln = gammaln(x+1);
else
    error('X must be an integer');
end
