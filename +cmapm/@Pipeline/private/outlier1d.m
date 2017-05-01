function oidx = outlier1d(x, varargin)
% OUTLIER1D Detect outliers in a univariate distribution.
%   OIDX = OUTLIER1D(X) Returns indices of values in X that are outside
%   median(X) +/- C*iqr(X). C is 1.5 by default.
%   OIDX = OUTLIER1D(X, 'cutoff', C) Sets the cutoff to C.

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