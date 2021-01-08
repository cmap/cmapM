function q = quote(c)
% double quote a cell array of strings
q = cellfun(@(x){sprintf('"%s"',x)}, c);
end