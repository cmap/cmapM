function gmt = parse_gmt(fname)
%PARSE_GMT Read .gmt Gene matrix transposed data format
% GMT = PARSE_GMT(FNAME) Reads .gmt file FNAME and returns the structure
% GMT. GMT is a nested structure GMT(1...NCOLS), where NCOLS is the number
% of rows in the GMT file. Each structure has the following fields:
%   head: column header, 1st column of the .gmt file 
%   desc: column description, 2nd column of the .gmt file 
%   len: length of the geneset
%   entry: cell array of column entries
% 
% Format Details:
% The GMT file format is a tab delimited file format that describes gene 
% sets. In the GMT format, each row represents a gene set. By contrast in 
% the GMX format, each column represents a gene set. Each gene set is 
% described by a unique geneset name, a brief description, and the genes 
% in the gene set. Unequal lengths (i.e. number of genes) are allowed. 
%
% CAVEAT: this code does not handle missing values

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

% 3/6/2008, returns nested structure instead of variables

try 
    fid = fopen(fname,'rt');
catch e
    rethrow(e);
end


gmt = struct('head',[],'desc',[],'len',[],'entry',[]);

rec=1;
while ~feof(fid)
    l=fgetl(fid);
    if ischar(l)
        f = textscan(l,'%s','delimiter','\t');
        gmt(rec, 1).head = char(f{1}(1));
        gmt(rec, 1).desc = char(f{1}(2));
        raw = f{1}(3:end);
        keep = ~cellfun(@isempty,raw);
        gmt(rec, 1).len = nnz(keep);
        gmt(rec, 1).entry = raw(keep);
        rec=rec+1;
    else
        warning('Error reading file %s at record %d, skipping the rest', fname, rec);
    end
end

fclose(fid);




