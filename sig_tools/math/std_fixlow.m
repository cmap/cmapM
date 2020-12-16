function sigma = std_fixlow(sigma,mu)
% STD_FIXLOW Adjusts for low standard deviation in data
%   SIGMAFIX = STD_FIXLOW(SIGMA,MU)
%
%   Inputs:
%           SIGMA: array of row-wise standard deviations (Nx1)
%           MU: array of row-wise means (NX1)
%   Outputs:
%           SIGMAFIX: array of fixed standard deviations (Nx1)
%
% From GSEA, Vector.java, stddev():
%      Some heuristics for adjusting variance based on data from affy chips
%
%      NOTE: problem occurs when we threshold to a value, then that 
%      artificially reduces the variance in the data.
%      First, we make the variance at least a fixed percent of the mean
%      If the mean is too small, then we use an absolute variance
%      
%      However, we don't want to bias our algs for affy data, e.g. we may
%      get data in 0..1 and in that case it is not appropriate to use
%      an absolute standard deviation of 10 - will kill the signal.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT


minallowed = 0.2 * abs(mu);
minallowed(~minallowed) = 0.2;

lowind = find(sigma < minallowed);
sigma(lowind) = minallowed(lowind);
