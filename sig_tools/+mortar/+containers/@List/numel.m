function n = numel(obj, varargin)
%NUMEL Number of elements in a list.
%   N = NUMEL(A) returns 1.  To find the number of elements, N, in the list
%   A, use PROD(SIZE(A)) or NUMEL(A,':').
%
%   N = NUMEL(A, VARARGIN) returns the number of subscripted elements, N, in
%   A(index1, index2, ..., indexN), where VARARGIN is a cell array whose
%   elements are index1, index2, ... indexN.
%
%   See also list/SIZE, list/LENGTH.

switch nargin
    case 1
        % return 1 else subsref and subasgn complain
        n = 1;
    otherwise
        if numel(varargin) ~= 1
            error('mortar:list:numel:NDSubscript', ...
                'You may only index into a list using a 1-D subscript.');
        end
        
        idx = varargin{1};
        if ischar(idx)
            if strcmp(idx,':') % already checked ischar
                n = obj.length;
            else % check this
                n = 1;
            end
        elseif isnumeric(idx) || islogical(idx) || iscellstr(idx)
            n = numel(idx);
        end
end
