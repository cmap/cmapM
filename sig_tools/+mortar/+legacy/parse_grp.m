function l = parse_grp(fname)
% PARSE_GRP Read GRP files
%   L = PARSE_GRP(FNAME) Reads a GRP format file. 
%
%   Format Details:
%   The GRP files contain a list in a simple newline-delimited
%   text format. Lines that start with a # are ignored.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

%l = textread(fname, '%s', 'delimiter','\n', 'commentstyle','shell');
if iscell(fname)
    l = fname;
elseif isfileexist(fname)
    fid = fopen(fname);
    l = textscan(fid, '%s', 'delimiter','\n', 'CommentStyle', '#');
    l = l{1}(~cellfun(@isempty, strtrim(l{1})));
    fclose(fid);
else
    error('mortar:parse_grp:InvalidInput', 'Invalid input')
end