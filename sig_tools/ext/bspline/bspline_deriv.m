function [dknots, dctrl] = bspline_deriv(order, knots, ctrl)
% Knots and control points associated with the derivative of B-spline curve.
%
% Input arguments:
% order:
%    B-spline order (2 for linear, 3 for quadratic, etc.)
% knots:
%    knot vector
% ctrl:
%    control points, typically 2-by-m, 3-by-m, or 4-by-m (for weights)
%
% Output arguments:
% dctrl:
%    control points of the derivative of the input B-spline curve
% dknots:
%    the new knot vector associated with the derivative B-spline curve

% Copyright 2011 Joe Hays
% Copyright 2010-2011 Levente Hunyadi

p = order - 1;
tmp = size(ctrl);
n = tmp(2)-1;
dim = tmp(1);

% derivative knots
dknots = knots(2:max(size(knots))-1);

% derivative control points
dctrl = zeros(dim,n);
for i = 1 : n
    dctrl(:,i) = (p / (knots(i+p+1) - knots(i+1))) * (ctrl(:,i+1) - ctrl(:,i));
end
