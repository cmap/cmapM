function s = encodeURL(url)
% encodeURL URL encode paths of a string delimited by /
tok = regexp(url, '(https?://)', 'tokens');
if ~isempty(tok{1})
    prefix = tok{1}{1};
    suffix = strrep(url, prefix, '');    
    t2 = tokenize(suffix, '/');
    for ii=2:numel(t2)
        t2{ii} = urlencode(t2{ii});
    end
    encoded = print_dlm_line(t2, 'dlm', '/');
    s = strcat(prefix, encoded);
else
    error('Expected input to start with pattern: https?://');
end
end

function urlOut = urlencode(urlIn)
%URLENCODE Replace special characters with escape characters URLs need

urlOut = char(java.net.URLEncoder.encode(urlIn,'UTF-8'));
end