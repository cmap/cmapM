function varargout = head(infile, n)
% HEAD Print the first N lines of a text file.
%
%   HEAD(INFILE) prints the first 10 lines of INFILE.
%   HEAD(INFILE, N) prints the first N lines of INFILE.
%   L = HEAD(...) returns the lines in a cell array L.
%

narginchk(1, 2)
if ~isvarexist('n')
    n=10;
else
    n = max(n, 1);
end

if nargout
    stdout = false;
    lines = cell(n, 1);
else
    stdout = true;
end

if isfileexist(infile)
    fid = fopen(infile, 'rt');
    ii=1;
    while ~feof(fid) && ii <= n;
        this_line = fgetl(fid);
        if stdout            
            fprintf('%s\n', this_line);
        else
            lines{ii} = this_line;
        end
        ii = ii+1;
    end
    fclose(fid);
end

if ~stdout
    varargout{1} = lines;
end
end