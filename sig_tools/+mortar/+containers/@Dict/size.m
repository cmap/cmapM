function varargout = size(obj, dim)
%SIZE Size of a Dictionary object.
%   D = SIZE(A) returns the two-element row vector D = [NEL, 1] containing
%   the number of elements in the dictionary A. The second dimension is
%   always 1.
%
%   [NROW, NCOL] = SIZE(A) returns the number of elements in the dictionary
%   A and number of columns (always 1) as separate output variables.
%
%   M = SIZE(A, DIM) returns the length of the dimension specified by the
%   scalar DIM.  For example, SIZE(A,1) returns the number of elements.
%   DIM>1 will return 1
%
%   See also DICT/LENGTH, DICT/NUMEL.

if nargin == 1
    if nargout < 2
        varargout = {[obj.length 1]};
    else
        varargout(1) = {obj.length};
        varargout(2:nargout) = {1};
    end
else % if nargin == 2
    if nargout > 1
        error('mortar:list:size:TooManyOutputs', ...
              'Too many outputs.');
    elseif ~isscalar(dim) || (dim < 1 || 2^31 < dim) || (round(dim) ~= dim)
        error('mortar:list:size:InvalidDim', ...
              'DIM must be a positive integer scalar in the range 1 to 2^31.');
    elseif dim == 1
        varargout = {obj.length};
    else
        varargout = {1};
    end
end
