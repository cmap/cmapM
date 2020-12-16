function [o, d, cutoff, pvalue] = xyoutlier(x,y,varargin)
% XYOUTLIER Detect outliers in 2d space using the Mahalanobis distance.
% [o, d, cutoff, pvalue] = xyoutlier(x,y,varargin)
pnames = {'pvalue'};
dflts = {0.975};
args = parse_args(pnames, dflts, varargin{:});

X = [x(:), y(:)];
d = mahal(X,X);
cutoff = chi2inv(args.pvalue, size(X,2));
o = d > cutoff;
pvalue = args.pvalue;