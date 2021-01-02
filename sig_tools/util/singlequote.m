function q = singlequote(c)
% double quote a cell array of strings
q = cellfun(@(x){sprintf('''%s''',x)}, c);
%q = regexprep(c, '^(.*)', '''$1''');
end