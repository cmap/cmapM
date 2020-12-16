function D = bspline_approx(k,t,x,M)
% B-spline curve control point approximation with known knot vector.
%
% Input arguments:
% k:
%    B-spline order (2 for linear, 3 for quadratic, etc.)
% t:
%    knot vector
% x:
%    B-spline values corresponding to which data points are observed
% M:
%    d-by-m matrix of observed data points, possibly polluted with noise,
%    d is typically 2 for plane, 3 for space, or 3 or 4, respectively, if
%    weights are present
%
% Output arguments:
% D:
%    d-by-n matrix of control points

% Copyright 2010 Levente Hunyadi

validateattributes(k, {'numeric'}, {'positive','integer','scalar'});
validateattributes(t, {'numeric'}, {'real','vector'});
validateattributes(x, {'numeric'}, {'real','vector'});
validateattributes(M, {'numeric'}, {'real','2d'});

B = bspline_basismatrix(k,t,x);
Q = M * B;
D = Q / (B'*B);
