function t = strtrunc(s, n)
% STRTRUNC Truncate a string.
%   T = STRTRUNC(S, N) Truncates string S at a maximum length of N. S can
%   be a character or a cell array.

error(nargchk(2,2, nargin));
if ischar(s)
    t=s(1:min(n, length(s)));
elseif iscell(s)    
    t = cellfun(@(x) x(1:min(length(x), n)), s, 'uniformoutput', false);    
else
    error('S must be a character or a cell array');
end
end