function varargout = size(obj, dim)
%SIZE Size of a List object.
%   D = SIZE(A) returns the two-element row vector D = [NROW, NCOL] containing
%   the number of rows and columns in the A. 
%
%   [NROW, NCOL] = SIZE(A) returns the number of rows and columns in the A
%   as separate output variables.
%
%   M = SIZE(A, DIM) returns the length of the dimension specified by the
%   scalar DIM.  For example, SIZE(A, 1) returns the number of rows and
%   SIZE(A, 2) returns the number of columns. DIM>2 will return 1
%
%   See also LIST/LENGTH, LIST/NUMEL.

if nargin == 1
    if nargout < 2
        varargout = {[obj.nrows obj.ncols]};
    else
        varargout(1:2) = {[obj.nrows obj.ncols]};
        varargout(2:nargout) = {1};
    end
else % if nargin == 2
    if nargout > 1
        error('mortar:containers:Table:size:TooManyOutputs', ...
              'Too many outputs.');
    elseif ~isscalar(dim) || (dim < 1 || 2^31 < dim) || (round(dim) ~= dim)
        error('mortar:containers:Table:size:InvalidDim', ...
              'DIM must be a positive integer scalar in the range 1 to 2^31.');
    elseif dim == 1
        varargout = {obj.nrows};
    else
        varargout = {obj.ncols};
    end
end
