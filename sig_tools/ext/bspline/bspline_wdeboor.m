function [C,u] = bspline_wdeboor(n,t,P,w,u)
% Evaluate explicit weighed B-spline at specified locations.
%
% Input arguments:
% n:
%    B-spline order (2 for linear, 3 for quadratic, etc.)
% t:
%    knot vector
% P:
%    control points, typically 2-by-m, 3-by-m or 4-by-m (for weights)
% w:
%    weight vector
% u (optional):
%    values where the B-spline is to be evaluated, or a positive
%    integer to set the number of points to automatically allocate
% Output arguments:
% C:
%    points of the B-spline curve

% Copyright 2010 Levente Hunyadi

w = transpose(w(:));
P = bsxfun(@times, P, w);
P = [P ; w];  % add weights to control points

if nargin >= 5
    [Y,u] = bspline_deboor(n,t,P,u);
else
    [Y,u] = bspline_deboor(n,t,P);
end

C = bsxfun(@rdivide, Y(1:end-1,:), Y(end,:));  % normalize and remove weights from computed points