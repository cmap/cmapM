function lines = parse_lines(fname)
if isfileexist(fname)
    fid = fopen(fname, 'rt');
    lines = textscan(fid, '%s', 'delimiter', '\n');
    lines = lines{1};
    fclose(fid);
else
    error('File not found: %s', fname)
end

end