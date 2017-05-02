function s = decodeURL(url)
% decodeURL Decode URL encode paths
s = urlDecode(url);
end

function urlOut = urlDecode(urlIn)
%URLENCODE Replace special characters with escape characters URLs need

urlOut = char(java.net.URLDecoder.decode(urlIn,'UTF-8'));
end