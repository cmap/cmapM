function [beta, stats]   = lr4fit(d, r, d2)

if ~isvector(d)
    error ('d should be a 1d vector of doses');
end

d = d(:);
nd = length(d);
nd2 = length(d2);
[p, n] = size(r);

if ~isequal(nd, p)
    error ('r should be a [p x n] matrix with p = length(d)');
end

%Estimated parameters
beta = zeros(n, 4);
% Predicted values using model
stats.ypred = zeros(nd2, n);
% half-width CI for prediction
stats.ydelta = zeros(nd2, n);
% 95% CI for parameters [LO HI]
stats.parci_lo = zeros(n, 4);
stats.parci_hi = zeros(n, 4);

MODEL = @lr4pmodel;

for ii=1:n
    % initial params
    b0 = lr4p_init(d, r(:,ii));
    
    opt = statset('Robust','off');
    % estimate parameters
    [beta(ii,:), resid, J, sigma] = nlinfit(d, r(:,ii), MODEL, b0, opt);
    
    % Regression diagnostics
    parci = nlparci(beta(ii,:), resid, 'covar',sigma);
    [ypred, delta]=nlpredci(MODEL, d2, beta(ii,:), resid,'covar',sigma);
    
    % stats
    stats.parci_lo(ii,:) = parci(:,1);
    stats.parci_hi(ii,:) = parci(:,2);
    stats.ypred(:,ii) = ypred;
    stats.ydelta(:,ii) = delta;
end
