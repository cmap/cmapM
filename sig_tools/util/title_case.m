function t = title_case(s)
% TITLE_CASE Apply Title Case capitalization to a string.

if ischar(s)
    t = title_case_(s);
elseif iscell(s)
    t = s;
    for ii=1:length(s)
        t{ii} = title_case_(s{ii});
    end
else
    error('Expect character or cell array input');
end


end

function t = title_case_(s)
t = lower(s);
is = isspace(t);
ind = [1, find(is(1:end-1))+1];
t(ind) = upper(t(ind));
end

