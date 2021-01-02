function tf = isrematch(s, re)
% ISREMATCH Test for regular expression match.
%   TF = ISREMATCH(S, RE) Returns true if if S matches the regular
%   expression RE. S can be a string or a cell array

if ischar(s)
    s = {s};
end
tf = ~cellfun(@isempty, regexp(s, re))';

end