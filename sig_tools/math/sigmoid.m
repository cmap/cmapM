function y = sigmoid(x, sgn, x0, k, m)
% SIGMOID Sigmoidal or logistic function
% SIGMOID(X, SGN, X0, K, M)
% SGN: sign of the function +1 for growth, -1 for decay 
% X0: x-value of the sigmoid's midpoint,
% K: the logistic growth rate or steepness of the curve
% M: the curve's maximum value
%
%% standard logistic growth function (SGN=-1, X0=0, K=1, M=1)
% x = linspace(-6, 6, 101);
% y = sigmoid(x, -1, 0, 1, 1);
% plot(x, y)

s = -sign(sgn);
y = (1*m)./(1 + exp(s*(x-x0)/k));
end