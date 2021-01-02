function [mu, sigma, w, delta] = huberize(x, dim)
% HUBERIZE Robust method of estimating location and scale
% [MU, SIGMA, W, DELTA] = HUBERIZE(X) Apply Huber's method to robustly
% estimate the mean MU and standard deviation SIGMA of X. W is the
% transformed version of X after iterative winsorization.
% [MU, SIGMA, W, DELTA] = HUBERIZE(X, DIM) operates along dimension DIM.
%
% References: Robust statistics: a method of coping with outliers
%             http://www.rsc.org/images/brief6_tcm18-25948.pdf
% 

% multplier for winsor limits
k  = 1.5;
% convergence criterion
epsilon = 1e-6;

% location estimation function
mu_func = @(x, dim) nanmean(x, dim);
% initial location estimate using median
initial_mu_func = @(x, dim) nanmedian(x, dim);

% scale estimation function
sigma_func = @(x, dim) nanstd(x, 0, dim);
% initial scale estimate using MAD
initial_sigma_func = @(x, dim) mad(x, 1, dim);

if ~isvarexist('dim')
    dim = 1;
end
assert(any(ismember(dim,[1,2])), 'Dimension must be 1 or 2');

% initial estimates of location and scale
[mu, sigma, c_low, c_high] = estimate_mu_sigma(x, k, dim,...
                                initial_mu_func, initial_sigma_func);

delta = inf;
w = x;
while delta > epsilon
%     dbg(1, 'Delta: %f', delta);
    mu0 = mu;
    sigma0 = sigma;
    w = winsorize_matrix(w, c_low, c_high, dim);
    [mu, sigma, c_low, c_high] = estimate_mu_sigma(w, k, dim,...
                                        mu_func, sigma_func);
    delta = mean((mu - mu0).^2 + (sigma - sigma0).^2);
end
 
end

function x = winsorize_matrix(x, c_low, c_high, dim)
if isequal(dim, 2)
    % by rows
    islow = bsxfun(@lt, x, c_low);
    [ir_low,~] = find(islow);
    ishigh = bsxfun(@gt, x, c_high);
    [ir_high,~] = find(ishigh);
    x(islow) = c_low(ir_low);
    x(ishigh) = c_high(ir_high);
else
    % by columns
    islow = bsxfun(@lt, x, c_low);
    [~, ic_low] = find(islow);
    ishigh = bsxfun(@gt, x, c_high);
    [~, ic_high] = find(ishigh);
    x(islow) = c_low(ic_low);
    x(ishigh) = c_high(ic_high);
end

end

function [mu, sigma, c_low, c_high] = estimate_mu_sigma(x, k, dim, mu_func, sigma_func)
mu = mu_func(x, dim);
sigma = sigma_func(x, dim);
c_low = mu - k*sigma;
c_high = mu + k*sigma;
end
