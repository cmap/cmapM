function m = parse_largevis(fname)
fid = fopen(fname, 'rt');
line = fgetl(fid);
x = textscan(line, '%d', 2, 'delimiter','\t');
dim = x{1};
fclose(fid);
dbg(1, 'Parsing %s dimensions [%d rows x %d cols]', fname, dim(1), dim(2));
%m = dlmread(fname, ' ', [1, 0, dim(1), dim(2)-1]);
m = dlmread(fname, ' ', 1, 0);
end