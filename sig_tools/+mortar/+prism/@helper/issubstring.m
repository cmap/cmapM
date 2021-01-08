% Determine whether string contains substring
% Returns logical array
% l = issubstring(str,sub)
% Arguments
%   str: string
%   sub: substring to match

function l = issubstring(str,sub)

if ~ischar(sub)
    error('Substring must be of class char');
end
s = strfind(str,sub);

if ischar(str)
    l = ~isempty(s);
elseif iscellstr(str)
    l = ~cellfun(@isempty,s);
else
    error('Input must be string or cell array of strings');
end