% GENCIRCLE generate points on a circle
%   [X,Y] = GENCIRCLE(X0, Y0, R, N) generates N point on a circle with
%   center at [X0,Y0] and radius equal to R.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function [x,y] = gencircle(x0, y0, r, N)

t = linspace(0,2*pi,N)';

x = r*cos(t) + x0;
y = r*sin(t) + y0;

