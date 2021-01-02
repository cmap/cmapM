function [D,w] = bspline_wapprox(k,t,x,M)
% B-spline curve control point estimation with weight approximation.
%
% Input arguments:
% k:
%    B-spline order (2 for linear, 3 for quadratic, etc.)
% t:
%    knot vector
% x:
%    B-spline values corresponding to which data points are observed
% M:
%    d-by-m matrix of observed data points, possibly polluted with noise

% Copyright 2010 Levente Hunyadi

n = numel(t)-k;  % number of control points to estimate
m = size(M,2);   % number of data points
lambda = 1;      % a number to ensure positivity of weights
I = eye(size(M,1),size(M,1));

Bc = bspline_basismatrix(k,t,x);
B = zeros(n,n);
A = zeros(n*(size(M,1)+1),n*(size(M,1)+1));
for i = 1 : m  % iterate over data points
	mi = M(:,i);  % data point
	ci = 1 / (1 + sum(mi.^2));

	Zi_11 = I - ci*mi*mi.';
	Zi_12 = ci*mi;
	Zi_21 = ci*mi.';
	Zi_22 = 1-ci;

	Bi = Bc(i,:).' * Bc(i,:);
	Ai = [ kron(Bi, Zi_11), kron(Bi, Zi_12) ...
	     ; kron(Bi, Zi_21), Bi .* Zi_22 ];

    A = A + Ai;
    B = B + Bi;
end

r = [ zeros(size(M,1)*n, 1) ; bspline_basissum(k,t,x) ];

% y = [ wD(:) ; w(:) ];  % column vector of unknowns
Bt = zeros(size(A));
Bt(end-size(B,1)+1:end,end-size(B,2)+1:end) = B;
y = (A + lambda*Bt) \ (lambda*r);
wd = y(1:size(M,1)*n);  % n weighed control points stacked in a vector
w = y(size(M,1)*n+1:end);
w = transpose(w(:));
D = zeros(size(M,1),n);  % n weighed control points
D(:) = -wd;
D = bsxfun(@rdivide, D, w);

function b = bspline_basissum(k,t,x)
% Sum of basis function values for a set of control points.

validateattributes(k, {'numeric'}, {'positive','integer','scalar'});
validateattributes(t, {'numeric'}, {'real','vector'});
validateattributes(x, {'numeric'}, {'real','vector'});

B = bspline_basismatrix(k,t,x);
b = sum(B,1);
b = b(:);
