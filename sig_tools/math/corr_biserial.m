function R = corr_biserial(X, D)
% CORR_BISERIAL Point biserial correlation
% Use when one variable (D) is dichotomous

is_one = D>0;
is_other = ~is_one;
n = size(X, 1);
n1 = sum(is_one, 1);
n0 = sum(is_other, 1);

m1 = sum(X.*is_one, 1)./n1;
m0 = sum(X.*is_other, 1)./n0;

s = std(X, 0, 1);

R = (m1 - m0) .* sqrt(n1.*n0/(n*(n-1))) ./ s;

end