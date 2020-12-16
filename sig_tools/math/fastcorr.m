function R = fastcorr(x, varargin)
% FASTCORR A faster replacement for the CORR function.
%   RHO = FASTCORR(X) returns a P-by-P matrix containing the pairwise
%   linear correlation coefficient between each pair of columns in the
%   N-by-P matrix X.
%   RHO = FASTCORR(X, Y) returns a P1-by-P2 matrix containing the pairwise
%   linear correlation coefficient between each pair of columns in the
%   N-by-P1 and N-by-P2 matrices X, Y.
%   RCORR = FASTCORR(X,Y,'name', value) specifies one or more optional
%   name/value pairs. Valid parameters are the following:
%       Parameter   Value
%       'type'      'Pearson' (default) to compute Pearson's linear
%                   correlation coefficient, 'Spearman' to compute
%                   Spearman's rho.
%       'is_standardized' Logical, false Standardizes the variable by 
%                   computing the zscore along columns of the
%                   input matrix. Set to true if inputs are pre-zscored.
%   Note: Does not compute pvalues or handle missing values
%   See also CORR

[n, p1] = size(x);

if (nargin < 2) || ischar(varargin{1})
    corrXX = true;
    p2 = p1;
else
    % Both x and y given
    y = varargin{1};
    varargin = varargin(2:end);
    if size(y,1) ~= n
        error('fastcorr:InputSizeMismatch', ...
              'X and Y must have the same number of rows.');
    end
    corrXX = false;
    p2 = size(y,2);
end

pnames = {'type', 'is_standardized'};
dflts = {'pearson', false}; 
args = parse_args(pnames,dflts,varargin{:});

switch lower(args.type)
    case 'pearson'
        type_is_pearson = true;
    case 'spearman'
        type_is_pearson = false;
        x = rankorder(x, 'dim', 1, 'fixties', true);
        if ~corrXX
            y = rankorder(y, 'dim', 1, 'fixties', true);
        end
    otherwise
        error('Unknown type %s', args.type);
end

if ~args.is_standardized || ~type_is_pearson
    zx = zscore(x, 0, 1);
    if corrXX
        R = zx'*zx/(n-1);
        % set the diagonal to 1 explicitly and avoid precision issues
        R(1:p1+1:end) = 1;
    else
        zy = zscore(y, 0, 1);
        R = zx'*zy/(n-1);
    end
else
    if corrXX
        R = x'*x/(n-1);
        R(1:p1+1:end) = 1;
    else        
        R = x'*y/(n-1);
    end
end