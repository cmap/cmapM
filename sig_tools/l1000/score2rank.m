function score = score2rank(score, varargin)
% SCORE2RANK Compute rank matrix from scores.
%   R = SCORE2RANK(S) Returns the rank matrix dataset R given a score
%   dataset.
%   SCORE2RANK(..., param1, value1,...) Specify optional parameters. Valid
%   parameters are:
%       'direc':   Sort order {'ascend','descend'}. Default is 'descend'
%       'dim': Dimension to operate on. 1 or 'column' for columns, 2 or 'row' for rows,
%              Default is 'column'
%       'ignore_nan': Ignore NaNs when ranking. Default is true. Note that
%                  ignoring NaNs is slower
%       'as_fraction' : Logical, returns ranks as a fraction of total rows 
%                       (or columns if dim is row)
%       'as_percentile' : Logical, returns ranks as a percentile of total 
%                          rows (or columns if dim is row)
%       'fixties' : Logical, adjusts for ties (is false by default).

pnames = {'direc', 'ignore_nan', 'dim',...
          'fixties', 'as_percentile', 'as_fraction'};
dflts = {'descend', true, 'column',...
          false, false, false};
args = parse_args(pnames, dflts, varargin{:});

[~, dim_val] = get_dim2d(args.dim);

score = parse_gctx(score);
score.mat = rankorder(score.mat, varargin{:}, 'direc', args.direc,...
    'as_percentile', args.as_percentile, 'as_fraction', args.as_fraction,...
    'fixties', args.fixties, 'ignore_nan', args.ignore_nan, 'dim', dim_val);
end