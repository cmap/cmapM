function [x,F] = bspline_footpoint(k,t,D,M)
% B-spline foot point of a set of points.
%
% M:
%    d-by-m matrix of observed data points, possibly polluted with noise,
%    which are not necessarily lying on the B-spline curve
%
% Output arguments:
% x:
%    parameter values for the B-spline foot points
% F:
%    foot points on the B-spline curve

% Copyright 2010 Levente Hunyadi

lb = t(k);
ub = t(end-k+1);

% simple algorithm, find close enough points
u = linspace(lb, ub, 500);
E = bspline_error(k,t,D,M,u);
[v,ix] = min(E,[],2);
x0 = u(ix);

if 1  % refine foot crude point estimates
    x = zeros(1,size(M,2));
    for i = 1 : size(M,2)
        x(i) = funminbnd(@(u) bspline_error(k,t,D,M(:,i),u), lb, ub, x0(i));
    end
else
    x = x0;
end

if nargin > 1
    F = bspline_deboor(k,t,D,x);
end

function E = bspline_error(k,t,D,M,x)
% B-spline approximation error.
%
% Input arguments:
% k:
%    B-spline order (2 for linear, 3 for quadratic, etc.)
% t:
%    knot vector
% D:
%    control points
% M:
%    points whose error to compute
% x:
%    parameter values w.r.t. which distance from m is minimized
%
% Output arguments:
% E:
%    sum of squares approximation error

Y = bspline_deboor(k,t,D,x);
Y = reshape(Y, size(Y,1), 1, size(Y,2));  % extend data with a singleton dimension
M = reshape(M, size(M,1), size(M,2), 1);
E = squeeze(sum(bsxfun(@minus, M, Y).^2, 1));  % calculate pairwise squared distance of points in M and Y
E = sqrt(E);  % pairwise distance
