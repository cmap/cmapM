function d = kld(x1, x2, varargin)
% KLD Compute the Kullback-Liebler Divergence between two random variables
% D = KLD(X1, X2)
% D = KLD(X1, X2, METRIC) METRIC is a string specifying variants of KLD
%   'kld' : K-L Divergence, the default
%   'sym' : Symmetricized KLD
%   'jsd' : Jensen-Shannon divergence

if ~isvector(x1) || ~isvector(x2)
    error(message('kld:VectorRequired'));
end

if ~isempty(varargin)
    metric = varargin{1};
else
    metric = 'kld';
end

% Remove missing observations indicated by NaN's, and
% ensure that valid observations remain.
x1  =  x1(~isnan(x1));
x2  =  x2(~isnan(x2));
x1  =  x1(:);
x2  =  x2(:);

if isempty(x1)
    error(message('kld:NotEnoughData', 'X1'));
end

if isempty(x2)
    error(message('kld:NotEnoughData', 'X2'));
end

% common axis to estimate densities
xmin = min([x1; x2]);
xmax = max([x1; x2]);
xi = linspace(xmin, xmax, 100);

% probability distributions
p1  =  ksdensity(x1, xi);
p1 = max(p1 / sum(p1), eps);
p2  =  ksdensity(x2, xi);
p2 = max(p2 / sum(p2), eps);

d = kld_prob(p1, p2, metric);

end

function d = kld_prob(p1, p2, metric)
switch(lower(metric))
    case 'kld'
        % K-L Divergence
        d = sum(p1 .* (log2(p1./p2)));
    case 'sym'
        % Symmetricized KLD
        d = 0.5 * (sum(p1 .* (log2(p1./p2))) + sum(p2 .* (log2(p2./p1))));
    case 'jsd'
        % Jensen-Shannon divergence
        q = 0.5 * (p1 + p2);
        d = 0.5 * (sum(p1 .* (log2(p1./q))) + sum(p2 .* (log2(p2./q))));        
    otherwise
        error('kld:UnknownMetric %s', metric)
end
end
