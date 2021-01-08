function y = adjustMeanVariance(x, b, method)
% adjustMeanVariance Apply mean, variance batch adjustment
%   Y = adjustMeanVariance(X, B)
% X is a [N x P] matrix
% B is a [N x 1] batch vector
% method = {'zscore', 'mean_center'}

MIN_SD = eps;
VALID_METHODS = {'zscore', 'mean_center'};
method = lower(method);
assert(any(ismember(method, VALID_METHODS)),...
    'Invalid method: %s', method)

[n, p] = size(x);
b = b(:);
nb = length(b);
assert(isequal(nb, n),...
    'expected length(B)=%d, found %d instead', n, nb);
switch(method)
    case 'zscore'
        y = standardizeBatches(x, b, MIN_SD);
    case 'mean_center'
        y = meanCenterBatches(x, b);
end

end

function y = standardizeBatches(x, b, MIN_SD)
% column means and std dev
grand_mean = nanmean(x, 1);
grand_sd = max(nanstd(x, [], 1), MIN_SD);

% standardize columns
z = bsxfun(@rdivide, bsxfun(@minus, x, grand_mean), grand_sd);

% batch stats
[batch_mean, batch_sd] = grpstats(z, b, {'nanmean', 'nanstd'});
batch_sd = max(batch_sd, MIN_SD);
uniq_b = unique(b, 'stable');
% batch indicator matrix
dm = bsxfun(@eq, b, uniq_b');

% standardize each batch
y = (z - dm * batch_mean) ./ (dm * batch_sd);

% re-scale to grand mean and sd
y = bsxfun(@plus, bsxfun(@times, y, grand_sd), grand_mean);

end

function y = meanCenterBatches(x, b)
grand_mean = nanmean(x, 1);

% batch means
batch_mean = grpstats(x, b, 'nanmean');

uniq_b = unique(b, 'stable');
% batch indicator ()
dm = bsxfun(@eq, b, uniq_b');

% mean-center each batch
y = (x - dm * batch_mean);

% re-scale using grand mean
y = bsxfun(@plus, y, grand_mean);

end