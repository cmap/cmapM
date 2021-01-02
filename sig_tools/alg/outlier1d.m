function oidx = outlier1d(x, varargin)
% OUTLIER1D Detect outliers in a univariate distribution.
%   OIDX = OUTLIER1D(X) Returns indices of values in X that are greater
%   than  Q3(X) + C*iqr(X) or less than Q3(X) + C*iqr(X). C is 1.5 by
%   default and corresponds to approximately +/- 2.7 sigma and 99.3
%   coverage if the data are normally distributed.
%
%   OIDX = OUTLIER1D(X, param1, value1,...) Specify optional parameters:
%   'cutoff', Double Specifies an alternate C used to call outliers using
%            the formulae specied above.
%   'tail', String Specify which tail of the distribution to examine for
%           outliers. Can be {['both'], 'left', 'right'}

pnames = {'cutoff', 'tail'};
dflts = {1.5, 'both'};
arg = parse_args(pnames, dflts, varargin{:});
pct = prctile(x(:), [25, 50, 75]);
wiqr = arg.cutoff * (pct(3) - pct(1));

switch(lower(arg.tail))
    case 'both'
        oidx = find(x < (pct(1) - wiqr) | x > (pct(3) + wiqr));
    case 'left'
        oidx = find(x < (pct(1) - wiqr));
    case 'right'
        oidx = find(x > (pct(3) + wiqr));
    otherwise
        error( 'Tail should be left, right or both')
        
end
end