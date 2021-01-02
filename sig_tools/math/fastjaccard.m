function [sim, c, u] = fastjaccard(x, varargin)
% FASTJACCARD Compute the Jaccard similarity between sets.
%   S = FASTJACCARD(X) Computes the Jaccard similarity between the rows of
%   a NxM binary matrix X. S is a NxN matrix where each element Sij is the
%   Jaccard similarity between set i and set j, defined as the ratio of
%   number of elements in intersection of i and j, to the number of
%   elements in union of i and j.
%
%   [S, C, U] = FASTJACCARD(X) also returns the number of common elements
%   (intersection) and union of sets i and j. The dimenstions of C and U
%   are the same as S.
%
%   [S, C, U] = FASTJACCARD(X, Y) compares rows of N x M matrix X to rows of 
%   P by M matrix Y. S is N x P matrix of Jaccard similarities.
%
%   Note that this is equivalent to 1-squareform(pdist(x, 'jaccard')), but
%   is implemented without loops and more performant.

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
        error('fastjaccard:InputSizeMismatch', ...
            'X and Y must have the same number of columns.');
    end
    corrXX = false;
    p = size(y, 1);
    y = castToDouble(y);
end

if corrXX
    % X vs X
    % intersection
    c = x * x';
    
    % number of elements in a pair of sets,
    % set zeros to one to handle empty sets causing DBZ
    s = max(diag(c), 1) * ones(1, n);
    
    % union
    u = s + s' - c;
else
    % X vs Y
    c = x * y';
    u = max(bsxfun(@plus, sum(x,2), sum(y,2)')-c, 1);
end
% jaccard similarity
sim = c ./ u;

end

function x = castToDouble(x)
if islogical(x)
    x = double(x);
elseif isnumeric(x)
    x = double(abs(x) > eps);
end
end