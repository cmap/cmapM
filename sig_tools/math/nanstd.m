function y = nanstd(varargin)
%NANSTD Standard deviation, ignoring NaNs.
%   Y = NANSTD(X) returns the sample standard deviation of the values in X,
%   treating NaNs as mssing values.  For a vector input, Y is the standard
%   deviation of the non-NaN elements of X.  For a matrix input, Y is a row
%   vector containing the standard deviation of the non-NaN elements in
%   each column of X. For N-D arrays, NANSTD operates along the first
%   non-singleton dimension of X.
%
%   NANSTD normalizes Y by (N-1), where N is the sample size.  This is the
%   square root of an unbiased estimator of the variance of the population
%   from which X is drawn, as long as X consists of independent, identically
%   distributed samples and data are missing at random.
%
%   Y = NANSTD(X,1) normalizes by N and produces the square root of the
%   second moment of the sample about its mean.  NANSTD(X,0) is the same as
%   NANSTD(X).
%
%   Y = NANSTD(X,FLAG,DIM) takes the standard deviation along dimension
%   DIM of X.
%
%   See also STD, NANVAR, NANMEAN, NANMEDIAN, NANMIN, NANMAX, NANSUM.

%   Copyright 1993-2004 The MathWorks, Inc.
%   $Revision: 2.10.2.5 $  $Date: 2004/07/28 04:38:43 $

% Call nanvar(x,flag,dim) with as many inputs as needed
y = sqrt(nanvar(varargin{:}));
