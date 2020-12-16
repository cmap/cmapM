% UNIQUE_ORD Set unique (ordered)
%   B = UNIQUE_ORD(A) for the array A returns the same values as in A but
%   with no repetitions. B will retain the same ordering as A. A can be a
%   cell array of strings.
%   
%   [B,I,J] = UNIQUE_ORD(...) also returns index vectors I and J such
%   that B = A(I) and A = B(J) (or B = A(I,:) and A = B(J,:)).

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT


function [b,ia, ib] = unique_ord(a)

[b,ia,ib] = unique(a);

[ia, iib] = sort(ia);
b = a(ia);
ib = iib(ib);
