function [sim, c, m] = fastoverlapcoef(x, varargin)
% FASTOVERLAPCOEF Compute the overlap coefficient between sets.
%   S = FASTOVERLAPCOEF(X) Computes the overlap coefficient between the
%   rows of a NxM binary matrix X. S is a NxN matrix where each element Sij
%   is the overlap coefficient between set i and set j, defined as the
%   ratio of number of elements in intersection of i and j, to the smaller
%   of number of elements in i and j. If set i is a subset of j or the
%   converse then the overlap coefficient is equal to one.
%
%   [S, C, M] = FASTOVERLAPCOEF(X) also returns C, the number of common
%   elements (intersection) and M minimum size of sets i and j. The
%   dimenstions of C and M are the same as S.
%
%   [S, C, M] = FASTOVERLAPCOEF(X, Y) compares rows of NxM matrix X to rows
%   of PxM matrix Y. S is N x P matrix of overlap coefficients.


[n, m] = size(x);

if (nargin < 2) || ischar(varargin{1})
    corrXX = true;
    p = n;
    x = castToDouble(x);
else
    % Both x and y given
    y = varargin{1};
    varargin = varargin(2:end);
    if size(y, 2) ~= m
        error('fastoverlapcoef:InputSizeMismatch', ...
            'X and Y must have the same number of columns.');
    end
    corrXX = false;
    p = size(y, 1);
    y = castToDouble(y);
end

if corrXX
    % intersection
    c = x * x';
    
    % number of elements in a pair of sets,
    % set zeros to one to handle empty sets causing DBZ
    s = max(diag(c), 1) * ones(1, n);
    
    % minimum set size
    m = min(s, s');
else
    % X vs Y
    c = x * y';
    m = max(bsxfun(@min, sum(x,2), sum(y,2)'), 1);
end

% overlap coefficient
sim = c ./ m;

end

function x = castToDouble(x)
if islogical(x)
    x = double(x);
elseif isnumeric(x)
    x = double(abs(x) > eps);
end
end