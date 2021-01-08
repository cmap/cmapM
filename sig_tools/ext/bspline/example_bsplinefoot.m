function example_bsplinefoot
% Illustrates B-spline foot point calculation.

% Copyright 2010 Levente Hunyadi

k = 4;
% knot sequence
t = [0 0 0 0 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1 1 1];
% control points
D = [ 0.1993 0.4965 0.6671 0.7085 0.6809 0.2938 0.1071 0.3929 0.5933 0.8099 0.8998 0.8906 ...
    ; 0.8377 0.8436 0.7617 0.6126 0.212 0.1067 0.3962 0.5249 0.5015 0.3991 0.6477 0.8553 ];
% points on B-spline curve
M = bspline_deboor(k,t,D);
P = M + 0.04 * randn(size(M));  % contaminate with noise
[x,F] = bspline_footpoint(k,t,D,P);

% plot control points and spline
figure;
hold all;
plot(D(1,:), D(2,:), 'g');
plot(M(1,:), M(2,:), 'b');
plot(P(1,:), P(2,:), 'kx');
plot(F(1,:), F(2,:), 'rx');
for i = 1 : size(P,2)
    line( ...
        [P(1,i), F(1,i)], ...
        [P(2,i), F(2,i)]);
end
hold off;
