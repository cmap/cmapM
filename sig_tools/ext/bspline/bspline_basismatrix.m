function [B,x] = bspline_basismatrix(n,t,x)
% B-spline basis function value matrix B(n) for x.
%
% Input arguments:
% n:
%    B-spline order (2 for linear, 3 for quadratic, etc.)
% t:
%    knot vector
% x (optional):
%    an m-dimensional vector of values where the basis function is to be
%    evaluated
%
% Output arguments:
% B:
%    a matrix of m rows and numel(t)-n columns

% Copyright 2010 Levente Hunyadi

if nargin > 2
    B = zeros(numel(x),numel(t)-n);
    for j = 0 : numel(t)-n-1
        B(:,j+1) = bspline_basis(j,n,t,x);
    end
else
    [b,x] = bspline_basis(0,n,t);
    B = zeros(numel(x),numel(t)-n);
    B(:,1) = b;
    for j = 1 : numel(t)-n-1
        B(:,j+1) = bspline_basis(j,n,t,x);
    end
end
