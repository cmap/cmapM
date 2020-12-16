function [ari, ri] = adjrand(x,y)
% ADJRAND Compute the adjusted Rand index comparing two classifications.
% ARI = ADJRAND(X, Y)
% This is a port of the R routine adjustedRandIndex {mclust}
% http://en.wikipedia.org/wiki/Rand_index
% http://rss.acs.unt.edu/Rdoc/library/mclust/html/adjustedRandIndex.html

% a = repmat(1:3, 1,3);
% lbl = {'A', 'B', 'C'};
% b = lbl(a);

% convert cell to numeric vector
[xi, ~ ] = grp2idx(x);
[yi, ~ ] = grp2idx(y);
if ~isequal(length(x), length(y))
    error('x and y should have the same length')
end
n = length(xi);
[mx, my] = meshgrid(1:n);
xx = xi(mx) == xi(my);
yy = yi(mx) == yi(my);
upper = triu(true(n), 1);
xx = xx(upper);
yy = yy(upper);

a = nnz(xx & yy);
b = nnz(xx & ~yy);
c = nnz(~xx & yy);
d = nnz(~xx & ~yy);
ni = b + a;
nj = c + a;
abcd = a + b + c + d;
q = (ni * nj) / abcd;
% adjusted rand index
ari = (a - q)/ ((ni + nj)/2 - q);
% rand index
ri = (a + d) / abcd;

