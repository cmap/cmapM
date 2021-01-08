function [dup, idx, gp, repnum, dupcnt ] = duplicates(x)
% DUPLICATES Find duplicates in a list.
%   DUP = DUPLICATES(X) returns duplicate elements in X. X can be a numeric
%   vector or a cell array of strings. 
%
%   [DUP, IDX, GP, REPNUM, DUPCNT] = DUPLICATES(X) also returns the indices
%   of duplicates IDX and a grouping variable GP such that IDX(GP==1) are
%   the indices of the first duplicate in DUP. REPNUM assigns an integer
%   from 1:DUPCNT for each duplicate. DUPCNT is the frequency for each
%   duplicate in X.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

x=x(:);
n = length(x);
[cn,nl] = getcls(x);
count = accumarray(nl(~isnan(nl)), ones(size(nl(~isnan(nl)))));

dupidx = find(count>1);
dup = cn(dupidx);
dupcnt = count(dupidx);

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
