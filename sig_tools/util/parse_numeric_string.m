function v = parse_numeric_string(s)
% PARSE_NUMERIC_STRING Extract scalar or list of numbers from comma separated string
% V = PARSE_NUMERIC_STRING(S)

assert(ischar(s), 'S muct be a carachter string')
v = str2double(tokenize(s, ',', true));

end