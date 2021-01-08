function [c,ia,ib] = intersectOrdered(a,b)
% Ordered intersection of two sets.
%   C = INTERSECT_ORD(A, B) returns the values common to both A and B. 
%   The result will be ordered as in B. A and B can be cell arrays of
%   strings.
%
%   [C, IA, IB] = INTERSECT_ORD(...) also returns index vectors IA and IB
%   such that C = A(iA) and C = B(iB).
%
%   Note: if A has duplicates which intersect with B then the last
%   occurring duplicate in A is reported
%   See also intersect

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

%Caveat: does not deal with duplicates

%c = a(ia) = b(ib)
[c, ia, ib] = intersect(a,b);

%keep original ordering of b
[ib ,ind ] = sort(ib);
ia = ia(ind);
c = b(ib);
