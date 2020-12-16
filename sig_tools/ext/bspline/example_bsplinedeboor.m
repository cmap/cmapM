function example_bsplinedeboor
% Illustrates drawing a B-spline.

% Copyright 2010 Levente Hunyadi

example_bspline_arc;
example_bspline_regular;
example_bspline_periodic;
example_bspline_weighed;

function example_bspline_arc

n = 3;
t = [ -2 -1 0 0.25 0.5 0.75 1 2 3 ];
P = [ 0.1993 0.4965 0.6671 0.7085 0.6809 0.2938 ...
    ; 0.8377 0.8436 0.7617 0.6126 0.212 0.1067 ];
X = bspline_deboor(n,t,P);
figure;
hold all;
plot(X(1,:), X(2,:), 'r');
plot(P(1,:), P(2,:), 'kv');
hold off;

function example_bspline_regular

n = 3;
t = [0 0 0 0 0.2 0.3 0.4 0.4 0.4 0.4 0.8 0.9 1 1 1 1];  % knot vector
P = [ 0.1993 0.4965 0.6671 0.7085 0.6809 0.2938 0.1071 0.3929 0.5933 0.8099 0.8998 0.8906 0.7339 ...
    ; 0.8377 0.8436 0.7617 0.6126 0.212 0.1067 0.3962 0.5249 0.5015 0.3991 0.6477 0.8553 0.9576 ];
X = bspline_deboor(n,t,P);

Xn = X + 0.02 * randn(size(X));
figure;
hold all;
plot(X(1,:), X(2,:), 'r');
plot(P(1,:), P(2,:), 'kv');
plot(Xn(1,:), Xn(2,:), 'bx');
hold off;

function example_bspline_periodic

n = 3;
t = [1 3 4 5 7 8 10 11 12 14];
P = [ 0.1993 0.4965 0.6671 0.7085 0.6809 0.1993 0.4965 ...
    ; 0.8377 0.8436 0.7617 0.6126 0.212 0.8377 0.8436 ];  % 7 points, 2 overlap
X = bspline_deboor(n,t,P);
figure;
hold all;
plot(X(1,:), X(2,:), 'r');
plot(P(1,:), P(2,:), 'k');
hold off;

function example_bspline_weighed

w = [1.4 0.5 1.6 1.8 0.7 1.4 0.5];  % weights
n = 3;
t = [1 3 4 5 7 8 10 11 12 14];
P = [ 0.1993 0.4965 0.6671 0.7085 0.6809 0.1993 0.4965 ...
    ; 0.8377 0.8436 0.7617 0.6126 0.212 0.8377 0.8436 ];  % 7 points, 2 overlap
Y = bspline_deboor(n,t,P);
X = bspline_wdeboor(n,t,P,w);
figure;
hold all;
plot(Y(1,:), Y(2,:), 'r');
plot(X(1,:), X(2,:), 'b');
plot(P(1,:), P(2,:), 'k');
hold off;
