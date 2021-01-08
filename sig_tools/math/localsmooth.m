function Z = localsmooth(Y, lambda)
m = size(Y, 1);
E = speye(m);
D1 = diff(E);
D2 = diff(D1);
P = lambda^2*(D2'*D2) + 2*lambda*(D1'*D1);
Z = (E+P)\Y;
end

