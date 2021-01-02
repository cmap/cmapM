function dbo = parse_json(json_file)
% PARSE_JSON Parse a json file
% PARSE_JSON(JSON_FILE)
fid = fopen(json_file, 'r');
s = fread(fid, inf, '*char');
fclose(fid);
dbo = parse_json_string(s);
end