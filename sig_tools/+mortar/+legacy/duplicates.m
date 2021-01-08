% DUPLICATES Find duplicates

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function [dup, idx, gp, repnum ] = duplicates(x)

x=x(:);
n = length(x);
[cn,nl] = mortar.legacy.getcls(x);
count = accumarray(nl, ones(size(nl)));

dupidx = find(count>1);
dup = cn(dupidx);

idx = nan(n,1);
gp = nan(n,1);
repnum = nan(n,1);

for ii=1:length(dupidx)
    reps = find(nl == dupidx(ii));
    idx(reps) = reps;
    gp(reps) = ii;
    repnum(reps) = 1:length(reps);
end

idx = idx(~isnan(idx));
gp = gp(~isnan(gp));
repnum = repnum(~isnan(repnum));
