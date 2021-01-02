function q = unquote(c)
% Remove single and double quotes from a cell array of strings
% Q = UNQUOTE(C) 

assert(iscell(c) || ischar(c), 'C must be a cell array or character string')
if ischar(c)
    is_input_char = true;
    c = {c};
else
    is_input_char = false;
end
q = cellfun(@(x){regexprep(x, '^[''"]|[''"]$', '')}, c);
if is_input_char
    q = q{1};
end
end