function y = richards_curve_5param(x, ymin, ymax, x0, k, T)
% RICHARDS_CURVE Generalized logistic curve
% Y = RICHARDS_CURVE_5PARAM(X, YMIN, YMAX, X0, K, T) 
% YMIN: Lower asymptote
% YMAX: Upper asymptote
% X0: Point of inflection on the x-axis
% K: Growth rate
% T: Asymmetry parameter

y = ymin + ((ymax - ymin)./((1+T*exp(-k*(x-x0))).^(1/T)));

end