function ll = binarylogloss(act, pred)
% BINARYLOGLOSS The logarithm of the likelihood function for a Bernoulli random
% distribution.
% $\-frac{1}{N}\sum{i=1}{N}y_ilog(p_i) + (1-y_i)log(1-p_i))$
%
% Measures the accuracy of a binary classifier. It is a soft measurment of
% accuracy that incorporates the notion of probabilistic confidence. 
% This error metric is used where contestants have to
% predict that something is true or false with a probability (likelihood)
% ranging from definitely true (1) to equally true (0.5) to definitely
% false(0).
% 
% The use of log on the error provides extreme punishments for being both
% confident and wrong. In the worst possible case, a single prediction that
% something is definitely true (1) when it is actually false will add
% infinite to your error score and make every other entry pointless. In
% Kaggle competitions, predictions are bounded away from the extremes by a
% small value in order to prevent this.
% https://www.kaggle.com/wiki/LogarithmicLoss

epsilon = 1e-15;
pred = max(epsilon, pred);
pred = min(1-epsilon, pred);
ll = sum(act.*log(pred) + (1-act).*log(1-pred));
ll = ll * -1.0/length(act);
end
