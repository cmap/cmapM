function l = parse_gz(fname, varargin)
% PARSE_GZ Parse a gzipped text file.
% L = PARSE_GZ(FNAME) Reads a text file FNAME, compressed using GZIP. L is
% a cell array of strings. Length(L) is equal to the number of lines in
% FNAME.

pnames = {'maxrow'};
dflts = {100000};
args = parse_args(pnames, dflts, varargin{:});

if isfileexist(fname)
    fid = java.io.BufferedReader(...
        java.io.InputStreamReader(...
        java.util.zip.GZIPInputStream(...
        java.io.FileInputStream(fname)...
        )...
        )...
        );

    ctr=1;
    l = cell(args.maxrow, 1);
    raw_line = char(fid.readLine());     
    
    while ~isempty(raw_line)        
        %l(ctr) = {strtrim(char(raw_line))};
        l{ctr} = raw_line;
        ctr = ctr + 1;
        raw_line = char(fid.readLine());
    end
    l = l(1:ctr-1);
else
    error('File: %s not found', fname);
end
end