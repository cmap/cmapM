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

gmt = parse_gmt(fname);

end

