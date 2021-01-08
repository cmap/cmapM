function d = hyperbolic_dist(XI, XJ)
%Computes the hyperbolic distance between point XI (1 x 2) and the m points
%stored in XJ (m x 2). The coordinates of these points are polar in the
%format (radial coord, angular coord). The resulting similarities are 
%stored in d.
%
%INPUT
%   XI -> The polar coordinates of a single point in the Poincaré disc.
%   XJ -> The polar coordinates of m points in the Poincaré disc.
%
%OUTPUT
%   d -> The hyperbolic distance between point XI and the other m points
%        stored in XJ. The hyperbolic distance between points (Ri, Ti) and
%        (Rj, Tj) in the hyperbolic space H^2 of curvature K = -1, 
%        represented by the Poincaré disc is:
%
% Dij = arccosh(cosh(Ri)*cosh(Rj) - sinh(Ri)*sinh(Rj)*cos(Tij));
%        
%        with Tij = pi - |pi - |Ti - Tj||
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

A =  pi - abs(pi - abs(XI(1, 2) - XJ(:, 2))); %angular separation between points

d = acosh(cosh(XI(1)).*cosh(XJ(:, 1)) - sinh(XI(1)).*sinh(XJ(:, 1)).*cos(A));

d(isinf(d)) = 0;