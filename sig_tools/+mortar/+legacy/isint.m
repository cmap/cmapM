% ISINT tests if input is an integer.
% ISINT(N) is True if N is an integer. N can be a scalar or a vector.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function yn = isint(n)

yn = n == fix(n);
