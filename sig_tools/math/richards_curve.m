function y = richards_curve(x, ymax, x0, k, nu)
% RICHARDS_CURVE Generalized logistic curve
% Y = RICHARDS_CURVE(X, YMAX, X0, K, NU) 
% YMAX: Upper asymptote
% X0: Point of inflection on the x-axis
% K: Growth rate
% NU: Asymmetry parameter
%
% References: 
% http://www.pisces-conservation.com/growthhelp/index.html?richards_curve.htm
% https://en.wikipedia.org/wiki/Generalised_logistic_function

y = ymax*(1+(nu - 1)*exp(-k*(x-x0))).^(1/(1-nu));

end