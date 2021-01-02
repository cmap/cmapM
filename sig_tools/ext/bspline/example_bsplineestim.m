function example_bsplineestim()
% Illustrates B-spline curve estimation without knowing parameter values.

% Copyright 2010 Levente Hunyadi

% spline order
k = 4;
% knot sequence
t = [0 0 0 0 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1 1 1];
% control points (unknown)
D_0 = [ 0.1993 0.4965 0.6671 0.7085 0.6809 0.2938 0.1071 0.3929 0.5933 0.8099 0.8998 0.8906 ...
      ; 0.8377 0.8436 0.7617 0.6126 0.212 0.1067 0.3962 0.5249 0.5015 0.3991 0.6477 0.8553 ];
% points on B-spline curve
M_0 = bspline_deboor(k,t,D_0,sort(rand(1,500)));
M = M_0 + 0.01 * randn(size(M_0));  % contaminate with noise

D = bspline_estimate(k,t,M);
C = bspline_deboor(k,t,D);

% plot control points and spline
figure;
hold all;
plot(D_0(1,:), D_0(2,:), 'g');
plot(M_0(1,:), M_0(2,:), 'b');
plot(M(1,:), M(2,:), 'kx');
plot(D(1,:), D(2,:), 'r');
plot(C(1,:), C(2,:), 'c');
legend('true control points', 'original curve', 'noisy data', 'estimated control points', 'estimated curve', ...
    'Location', 'Best');
hold off;
