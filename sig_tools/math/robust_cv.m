function cvar = robust_cv(m, dim, flag)
% ROBUST_CV Robust coefficient of variation.
%
% CVAR = ROBUST_CV(M) Compute coefficient of variation (C.V.) of an input
% matrix M. Zero median rows are returned as NaNs. CVAR is computed as:
% CVAR = mad(M, 0, 1) ./ median(M, 1);
%
% CVAR = ROBUST_CV(M, dim) computes the C.V. along the dimension dim.
%
% CVAR = ROBUST_CV(M, dim, flag) Scales the C.V. for normally distributed
% data. If flag is 1 the C.V. is multipled by 1.4826. The default is
% flag=0, in which case the data is not scaled.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

if ~isvarexist('dim')
    dim = 1;
end

if ~isvarexist('flag')
    flag = 0;
end

if flag
    scale = 1.4826;
else
    scale = 1;
end
    
cvar = scale * mad(m, 1, dim) ./ median(m, dim);

