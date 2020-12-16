function example_bsplinebasis
% Illustrates B-spline basis functions.

% Copyright 2010 Levente Hunyadi

t = [0 0 0 0.5 1 1 1];  % knot vector
n = 3;  % quadratic spline
figure( ...
    'Name', sprintf('NURBS basis functions of order %d', n));
hold all;
for j = 0 : numel(t)-n-1
    [y,x] = bspline_basis(j,n,t);
    plot(x, y);
end
hold off;

% the bell-shaped curve
figure( ...
    'Name', 'The bell-shaped curve');
hold all;
x = 0 : 0.1 : 3;
y = bspline_basis(0, 3, [0 1 2 3], x);
plot(x,y);
hold off;

% the linear case
figure( ...
    'Name', 'The linear case');
hold all;
x = 0 : 0.1 : 3;
y = bspline_basis(0, 2, [0 3 3], x);
plot(x,y);
hold off;

% the constant case
figure( ...
    'Name', 'The constant case');
hold all;
x = 0 : 0.1 : 3;
y = bspline_basis(0, 1, [0 3], x);
plot(x,y);
hold off;
