function [d,ind] = finddup(l)
% FINDDUP find duplicates
%   FINDDUP(L)  when L is a vector returns duplicate values 
%   in L. L can be can be a cell array of strings
%
%   [D, I] = FINDDUP(L) also returns index vector I such that 
%   D = L(I)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

[u,i] = unique(l);

ind = setdiff(1:length(l),i);
[d,ind2] = unique(l(ind));
ind = ind(ind2);
