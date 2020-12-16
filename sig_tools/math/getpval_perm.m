% GETPVAL_PERM Compute a p value for a permutation test.
%   P = GETPVAL_PERM(OBS, PERM) Returns the proportion of sampled
%   permutations which are greater than OBS (for positive OBS), or the
%   proportion of permutations which are less than OBS (for negative OBS).

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function p = getpval_perm(x, d)

tot = length(d);
sx = sign(x);

cnt = length(find(sx*d > sx*x));

% if (x>=0)
%     cnt = length(find(d>x));
% else
%     cnt = length(find(d<x));
% end
disp(cnt)
p = cnt/tot;
