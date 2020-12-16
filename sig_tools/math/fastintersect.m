function c = fastintersect(x, varargin)
% FASTINTERSECT Compute the intersection between sets.
%   S = FASTINTERSECT(X) Computes the intersection between the rows of
%   a NxM binary matrix X. S is a NxN matrix where each element Sij is the
%   intersection between set i and set j.
%
%   S = FASTINTERSECT(X, Y) compares rows of NxM matrix X to rows
%   of PxM matrix Y. S is N x P matrix of set intersections.


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
        error('fastintersect:InputSizeMismatch', ...
            'X and Y must have the same number of columns.');
    end
    corrXX = false;
    p = size(y, 1);
    y = castToDouble(y);
end

if corrXX
    % intersection
    c = x * x';
else
    % X vs Y
    c = x * y';
end

end

function x = castToDouble(x)
if islogical(x)
    x = double(x);
elseif isnumeric(x)
    x = double(abs(x) > eps);
end
end