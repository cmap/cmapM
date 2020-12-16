function list = parseFile_(obj, fname)
% Parse list from a text file.
%   Format Details:
%   The files contain a list in a simple newline-delimited
%   text format. Lines that start with a # are ignored.

if mortar.legacy.isfileexist(fname)
    fid = fopen(fname);
    list = textscan(fid, '%s', 'delimiter','\n', 'CommentStyle', '#');
    list = list{1}(~cellfun(@isempty, strtrim(list{1})));
    fclose(fid);
else
    error('File not found: %s', fname)
end