function [re, ce, ge, x] = median_polish(x, tol, max_iter)
% MEDIAN_POLISH Fits additive model using Tukey's median polish procedure.
%
% [RE, CE, GE, RES] = MEDIAN_POLISH(X) Fits Tukey's additive model
% to a 2D input matrix X such that:
%
%   X = RE + CE + GE + RES
%
% The algorithm works by alternately removing the row and column medians,
% and continues until the proportional reduction in the sum of absolute
% residuals is less than the tolerance or until there have been maxiter
% iterations (See below on how to set these parameters). The function
% returns the row effects RE as a column vector of length size(X, 2),
% column effects CE as a row vector of length size(X, 1), grand (or
% overall) effect GE as a scalar and the residuals RES as a matrix of
% size(X).
%
% MEDIAN_POLISH(X, TOL) Specify tolerance threshold for stopping
% iterations. Default is 0.01
%
% MEDIAN_POLISH(X, TOL, MAX_ITER) Specify maximum number of iterations.
% Default is 100.
%
% Example:
% x = [14, 15, 14; 7, 4, 7; 8, 2, 10; 15, 9, 10; 0, 2, 0];
% [re, ce, ge, res] = median_polish(x)
% % Check decomposition
% abs(x-(bsxfun(@plus,re,ce)+res+ge))<eps

% Based on R's medpolish() function from the stats package
% Rajiv Narayan, 2012

nin = nargin;
assert (nin>0, 'Must have at least one input')
if nin < 2
    tol = 0.01;
end
if nin < 3
    max_iter = 100;
end
[nr, nc] = size(x);
assert(ismatrix(x), 'X should be a 2d matrix');
assert (tol > 0, 'Tolerance should be a positive non-zero value');
assert (max_iter > 0, 'Maximum iterations must be greater than zero');

x0 = x;
% row effect
re = zeros(nr, 1);
% column effect
ce = zeros(1, nc);
% grand / overall effect
ge = 0;
oldsum = 0;
for ii=1:max_iter
    % row median    
    rm = nanmedian(x, 2);
    % update residuals
    x = bsxfun (@minus, x, rm);    
    % update row effect
    re = re + rm;
    
    cmm = nanmedian(ce);
    ce = ce - cmm;
    ge = ge + cmm;        
    
    % column median
    cm = nanmedian(x, 1);
    % update residuals
    x = bsxfun(@minus, x, cm);
    % update column effect
    ce = ce + cm;
    
    rmm = nanmedian(re);
    re = re - rmm;
    ge = ge + rmm;
            
    % test for convergence
    newsum = nansum(abs(x(:)));
    has_converged = (newsum < eps || abs(newsum - oldsum) < tol*newsum);
    if has_converged
        break;        
    end
    oldsum = newsum;
    dbg(1, '%d/%d sum: %f', ii, max_iter, newsum);
end
if has_converged
    dbg(1, 'Final: %f in %d iterations', newsum, ii);
else
    warning('%s did not converge in %d iterations', mfilename, max_iter)
end

end