% FLIP_CORRECTION Check and adjust mis-assigned peaks.
% [Y, FLIPS] = FLIP_CORRECTION(X) X is a [2N x F] matrix. Trains a linear
% discriminant classifier to identify mis-assignments. Y is a matrix of the
% same dimensions as X with the adjusted signal. FLIPS is a vector of
% indices (1:N) that were mis-assignments were detected.

function [y, flips, posterior, logp] = flip_correction_nd(x, flip_cutoff, method)

if ~isdefined('method')
    method = 'linear';
end

[r,c] = size(x);
ng = 2;
ns = r/ng;
if ~isequal(ns, round(ns))
    error('X should have an even number of rows.')
end
% x0 = x(:);
flips = [];
if ~any(isnan(x(:))) || any(isinf(x(:)))
    % grouping variable
    clvec = num2cellstr(reshape(repmat(1:ng, ns, 1), r, 1));
    % discriminant analysis
    [class, err, posterior, logp] = classify(x, x, clvec, method);
    flips = find(posterior(1:ns, 2)>flip_cutoff & posterior(ns + (1:ns), 1)>flip_cutoff);
end
% correct flips
y = x;
if ~isempty(flips)    
    y(flips, :) = x(ns+flips, :);
    y(ns+flips, :) = x(flips, :);
end