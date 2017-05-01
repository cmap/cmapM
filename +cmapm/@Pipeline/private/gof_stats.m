% GOF_STATS Compute goodness of fit statistics.
% STATS = GOF_STATS(Y, YPRED, Q) Computes goodness-of-fit statistics for
% model prediction. Y is a [n x m] matrix of observed responses where n is
% the number of observations and m is the number of dependent variables,
% YPRED is a [n x m] matrix of values predicted by the model, Q is the
% number of coefficients used in the model (including the intercept term if
% any). STATS is a structure with the following fields:
% Rsq - R square
% Rsq_adj - adjusted R square
% Stderr - Standard error
% F - F statistic
% pvalue - pvalue for F statistic

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function stats = gof_stats(y, ypred, q)

% sizes should match
if ~isequal (size(y), size(ypred))
    error('Y and YPRED should have the same size');
end
if ~isscalar(q) || ~isequal(fix(q),q)
    error('Q should be an integer');
end

% sample size
n = size(y,1);
if any( [q<=1, n<=q])
    error ('Invalid degrees of freedom. The following should hold Q>1 and N>Q. (q=%d, n=%d)',q,n);
end

% total sum of squares
sst = sum(bsxfun(@minus, y, mean(y)).^2);

% error sum of squares
sse = sum((y - ypred).^2);

%degrees of freedom
dft = n-1;
dfe = n-q;
dfr = q-1;

% mean sum of sq
mst = sst / dft;
mse = sse / dfe;
msr = (sst - sse) / dfr;

% R square
Rsq = 1 - (sse./sst);
% adjusted R square
Rsqadj = 1 - (mse./mst);
%standard error
rms = sqrt(mse);
% F statistic
F = msr./mse;
% p value
pvalue = 1 - fcdf(F, dfr, dfe);

stats = struct('rsquare', Rsq, ...
        'adjrsquare', Rsqadj, ...
        'rmse', rms,...
        'F', F,...
        'pvalue', pvalue);
