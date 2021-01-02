% PARSE_GCT_HEADER Parse header information from a gct file.
%   [NROWS, NCOLS, COLNAMES] = PARSE_GCT_HEADER(FNAME) Reads first three
%   lines of a GCT file and returns the number of rows, the number of
%   columns and a cell array of column names.
%
%   See Also: parse_gct

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function [nr,nc,sid] = parse_gct_header(fname)

try
    fid = fopen(fname,'rt');
catch
    rethrow(lasterror);
end

%read headerlines
%first line
l1=fgetl(fid);

%second line
l2=fgetl(fid);

%number of features(genes) and samples
[nr,nc]=strread(l2,'%d\t%d');

%third line
l3=fgetl(fid);

x=strread(l3,'%s','delimiter','\t');

%sample ids
sid={(x{3:end})}';


fclose (fid)
