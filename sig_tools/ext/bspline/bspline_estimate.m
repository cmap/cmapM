function D = bspline_estimate(k,t,M)
% B-spline curve control point estimation without knowing parameter values.
%
% Input arguments:
% k:
%    B-spline order (2 for linear, 3 for quadratic, etc.)
% t:
%    knot vector
% M:
%    d-by-m matrix of observed data points, possibly polluted with noise,
%    d is typically 2 for plane, 3 for space, or 3 or 4, respectively, if
%    weights are present
%
% Output arguments:
% D:
%    d-by-n matrix of control points

% Copyright 2010 Levente Hunyadi

x = linspace(t(k), t(end-k+1), size(M,2));  % allocate points uniformly
for iter = 1 : 50
    D = bspline_approx(k,t,x,M);
    x = bspline_footpoint(k,t,D,M);
    if 0
        C = bspline_deboor(k,t,D);
        Y = bspline_deboor(k,t,D,x);
        hold on;
        plot(C(1,:), C(2,:), 'b');
        plot(M(1,:), M(2,:), 'kx');
        plot(Y(1,:), Y(2,:), 'rx');
        hold off;
    end
end