function l = parse_gz(fname, varargin)
% PARSE_GZ Parse a gzipped text file.
% L = PARSE_GZ(FNAME) Reads a text file FNAME, compressed using GZIP. L is
% a cell array of strings. Length(L) is equal to the number of lines in
% FNAME.

pnames = {'maxrow'};
dflts = {100000};
args = parse_args(pnames, dflts, varargin{:});

if isfileexist(fname)
    try
        % try using zcat
        [status, l] = system(sprintf('zcat "%s"', fname));
        if isequal(status,0)
            l = textscan(l, '%s', 'delimiter', '\n');
            if ~isempty(l)
                l = l{1};
            end
        else
            error('Error Reading file: %s', l)
        end
        
    catch
        % fallback to java routine
        fid = java.io.BufferedReader(...
            java.io.InputStreamReader(...
            java.util.zip.GZIPInputStream(...
            java.io.FileInputStream(fname)...
            )...
            ,'UTF8')...
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
    end

else
    error('File: %s not found', fname);
end
end