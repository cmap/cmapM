function example_bsplineapprox
% Illustrates B-spline curve approximation.

% Copyright 2010 Levente Hunyadi

example = menu('Choose an example', 'Demonstration example 1', 'Demonstration example 2');
useweights = false;

%example = 1;
switch example
    case 1
        % spline order
        k = 4;
        % knot sequence
        t = [0 0 0 0 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1 1 1];
        % control points (unknown)
        D_0 = [ 0.1993 0.4965 0.6671 0.7085 0.6809 0.2938 0.1071 0.3929 0.5933 0.8099 0.8998 0.8906 ...
              ; 0.8377 0.8436 0.7617 0.6126 0.212 0.1067 0.3962 0.5249 0.5015 0.3991 0.6477 0.8553 ];
        % points on B-spline curve
        [M_0,x] = bspline_deboor(k,t,D_0);
        M = M_0 + 0.01 * randn(size(M_0));  % contaminate with noise
    case 2
        k = 4;
        t = [0 0 0 0 0.2 0.4 0.6 0.8 1 1 1 1];
        w = 2*[1.4 0.5 1.6 1.8 0.7 1.9 1.5 0.9];
        D_0 = [0.09942 0.1398 0.4942 0.6787 0.8573 0.4741 0.4856 0.987;0.05994 0.5132 0.5716 0.2617 0.6711 0.7237 0.9839 0.7939];
        [M_0,x] = bspline_wdeboor(k,t,D_0,w);
        M = M_0 + 0.01 * randn(size(M_0));
end

if useweights  % weighed approximation
    [D,w] = bspline_wapprox(k,t,x,M);
    disp('Control point weights:');
    disp(w);
else  % unweighed approximation
    D = bspline_approx(k,t,x,M);
end

% plot control points and spline
figure;
hold all;
plot(D_0(1,:), D_0(2,:), 'g');
plot(M_0(1,:), M_0(2,:), 'b');
plot(M(1,:), M(2,:), 'kx');
plot(D(1,:), D(2,:), 'r');
legend('true control points', 'original data', 'noisy data', 'estimated control points', ...
    'Location', 'Best');
hold off;
