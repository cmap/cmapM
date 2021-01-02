function cvar = cv(m)
% CV Compute coefficient of variation.
%
% CVAR = CV(M) Compute the coefficient of variation (CVAR) of an input
% matrix M. Zero mean rows are returned as NaNs. CVAR is computed as:
% cvar = std(m,0,2)./mean(m,2);

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

cvar = std(m,0,2)./mean(m,2);

