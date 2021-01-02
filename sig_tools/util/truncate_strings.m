function out = truncate_strings(s, n)

% OUT = TRUNCATE_STRINGS(S,N)
% Given a string or a cell array of strings, function returns 
% first n or last n (if provided as a negative number) characters of
% input string(s)

if ischar(s)
    out = truncate(s,n);
elseif iscell(s)
   idx = cellfun(@ischar, s);
   if sum(idx)~=numel(s)
       error('%s> Non-string entry in your input cell array was detected',...
            mfilename)
       %s = cellfun(@stringify, s,'uni',0);    
   end
   out = cellfun(@(x) truncate(x,n), s, 'uni',0);
else
    error('%s> Incorrect input type. It should be a string or a cell array of strings',mfilename)
end

function t = truncate(s,n)

nc = numel(s);
if abs(n)>=nc
    t = s;
else
    if n<0
        t = s(end+n+1:end);
    elseif n>0
        t = s(1:n);
    else
        t = s;
    end
end