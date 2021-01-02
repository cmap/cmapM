function varargout = tail(infile, n)
% TAIL Print the last N lines of a text file.
%
%   TAIL(INFILE) prints the last 10 lines of INFILE.
%   TAIL(INFILE, N) prints the last N lines of INFILE.
%   L = TAIL(...) returns the lines in a cell array L.
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
    status = fseek(fid, 0, 'eof');
    if status==0
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
    end
    fclose(fid);
end

if ~stdout
    varargout{1} = lines;
end
end