function tf = isCellNumeric(s)
%IsCellNumeric True for cell array of numeric values.
%   IsCellNumeric(S) returns 1 if S is a cell array of numeric values and 0
%   otherwise.
%
%   See also IsCellString

if isa(s,'cell')
    res = ismember(cellfun(@class, s, 'uniformoutput', false), ...
        mortar.util.DataType.NUMERIC_TYPES);
    tf = all(res(:));
else
    tf = false;
end
