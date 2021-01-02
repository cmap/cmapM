function bi = bicov(x, y)
% BICOV Calculate biweight midcovariance.
%   BI = BICOV(X, Y)
% from Wilcox (1997).
% http://www.unt.edu/benchmarks/archives/2001/december01/rss.htm

mx = median(x);
my = median(y);
ux = abs((x - mx)/(9 * norminv(0.75) * mad(x)));
uy = abs((y - my)/(9 * norminv(0.75) * mad(y)));
aval = zeros(size(ux));
bval = zeros(size(uy));
aval(ux <= 1) =  1;
bval(uy <= 1) = 1;
top = sum(aval .* (x - mx) .* (1 - ux.^2).^2 .* bval .* (y - my) .* (1 - uy.^2).^2);
top = length(x) * top;
botx = sum(aval .* (1 - ux.^2) .* (1 - 5 .* ux.^2));
boty = sum(bval .* (1 - uy.^2) .* (1 - 5 .* uy.^2));
bi = top/(botx * boty);

