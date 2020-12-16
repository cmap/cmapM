function e = rmse(x, y, varargin)
% RMSE  Root mean square error of two vectors.
% E = RMSE(X,Y) Compute the root mean square deviation between X and Y. X
% and Y can be vectors or matrices.
%
% E = RMSE(X,Y, PARAM1, VALUE1,...) Specify optional parameters
% 'metric': string, metic for squared deviation. Valid options are:
%   'rmsd': Root mean square deviation. The default.
%           E = SQRT(MEAN(X-Y).^2)
%   'pct_rmsd': Percent change RMSD
%           E = 100 * SQRT(MEAN(((X-Y)./X).^2))
%   'nrmsd': Normalized RMSD, RMSD scaled to the range of values in X
%           E = RMSD(X,Y) / (MAX(X)- MIN(X))
%   'cv_rmsd': 
%           E = RMSD(X, Y) / MEAN(X)
%   Note: nrmsd and cv_rmsd assume X is the reference and are not symmetric.
%
% 'usemedian': boolean, Use median instead of mean when computing the
%              metric. Default is false
%
% See: http://en.wikipedia.org/wiki/Mean_squared_error
% http://en.wikipedia.org/wiki/Root_mean_square_deviation

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

% convert to column vectors
x=x(:);
y=y(:);

pnames = {'metric', 'usemedian'};
dflts = {'rmsd', false};
arg = parse_args(pnames, dflts, varargin{:});


if ~isequal(length(x), length(y))
    error('X and Y should have the same dimensions')
end

%mean or median
if arg.usemedian
    middle = @nanmedian;
else
    middle = @nanmean;
end

switch (arg.metric)
    case 'rmsd'
        %RMSD [default]
        e = sqrt(middle((x-y).^2));
    case 'pct_rmsd'
        %PCT Change
        e = 100 * sqrt(middle(((x-y)./x).^2));
    case 'nrmsd'
        %normalized rmsd
        xmax = nanmax(y);
        xmin = nanmin(y);
        e = rmse(x, y, 'usemedian', arg.usemedian) / (xmax - xmin);
    case 'cv_rmsd'
        % cv rmsd
        e = rmse(x, y, 'usemedian', arg.usemedian) / middle(x);
    otherwise
        error('Unknown metric: %s', arg.metric);
end
