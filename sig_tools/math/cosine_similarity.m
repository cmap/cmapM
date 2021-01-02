function S = cosine_similarity(x, varargin)
% COSINE_SIMILARITY Cosine similarity
%   S = COSINE_SIMILARITY(X) returns a P-by-P matrix containing the
%   pairwise cosine similarity between each pair of columns in the N-by-P
%   matrix X. 
%
%   S = COSINE_SIMILARITY(X, Y) returns a P1 x P2 matrix
%   containing the pairwise cosine similarity between each pair of columns
%   in the N x P1 and N x P2 matrices X, Y.

[n, p1] = size(x);

if (nargin < 2) || ischar(varargin{1})
    corrXX = true;
    p2 = p1;
else
    % Both x and y given
    y = varargin{1};
    varargin = varargin(2:end);
    if size(y,1) ~= n
        error('cosine_similarity:InputSizeMismatch', ...
              'X and Y must have the same number of rows.');
    end
    corrXX = false;
    p2 = size(y,2);
end

if corrXX
    % unit vectors in the same direction as x
    mag_x = getMagnitude(x);
    x = bsxfun(@rdivide, x, mag_x);
    % pairwise dot product of the unit vectors = cosine of angle between
    % them
    S = x'*x;    
else
    % unit vectors in the same direction as x
    mag_x = getMagnitude(x);
    x = bsxfun(@rdivide, x, mag_x);
    
    % unit vectors in the same direction as y
    mag_y = getMagnitude(y);
    y = bsxfun(@rdivide, y, mag_y);

    S = x'*y; 
end

end

function mag_x = getMagnitude(x)
    if verLessThan('matlab', '9.3')
        mag_x = sqrt(sum(x.^2, 1));
    else
        mag_x = vecnorm(x, 2, 1);
    end
end