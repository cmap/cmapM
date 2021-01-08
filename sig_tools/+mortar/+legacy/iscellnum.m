function tf = iscellnum(s)
%ISCELLNUM True for cell array of numeric values.
%   ISCELLNUM(S) returns 1 if S is a cell array of numeric values and 0
%   otherwise.
%
%   See also ISCELLSTR

if isa(s,'cell'),
    res = ismember(cellfun(@class, s, 'uniformoutput', false), ...
        mortar.legacy.numeric_type);
    tf = all(res(:));
else
    tf = false;
end
