function u = unescape(v)
% Unescape strings passed from the command line.
%
% Example:
% v={'foo', 'foo\', 'bar', 'zog', 10, 'abc\','\','rty'};
% unescape(v)

u = v;
isstring = find(cellfun(@ischar, v));
idx = isstring(~cellfun(@isempty, regexp(v(isstring),'\\$')));

if ~isempty(idx)
    discard = false(size(v));
    u(idx) = regexprep(u(idx), '\\$', '');
    didx = [diff(idx), 0];
    cur = idx(1);
    nu=length(u);
    for ii=1:length(idx)
        if (idx(ii)+1) <= nu
            u{cur} = sprintf('%s %s', u{cur}, u{idx(ii)+1});
            discard(idx(ii)+1) = true;
            if didx(ii) > 1
                cur = idx(ii+1);
            end
        else
            u{cur} = v{cur};
        end
    end    
    u(discard) = [];
end
end