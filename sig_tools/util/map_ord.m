function [c, ia, ib] =  map_ord(a, b)
% MAP_ORD Map elements in two lists.
% [C, IA, IB] = MAP_ORD(A, B) C contains elements shared between A and B
% ordered according to B such that C = A(IA) = B(IB). If B has duplicates
% then elements in C are duplicated to match the ordering in B. This is
% different from set operations like INTERSECT that return non-duplicated
% sets. If B has no duplicates this is equivalent to INTERSECT_ORD(A, B)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
a= a(:);
b = b(:);
na = length(a);
nb = length(b);
ua = unique(a);
ub = unique(b);

if isequal(na,length(ua)) && isequal(nb, length(ub))
    % no duplicates
    [c, ia, ib ] = intersect_ord(a, b);
else
    if isnumeric(b)
        b = num2cell(b);
    end
    hm = mortar.containers.Dict(a, 1:length(a));
    isk = hm.iskey(b);    
    c = b(isk);    
    ia = hm(c);
    ib = find(isk);
end
