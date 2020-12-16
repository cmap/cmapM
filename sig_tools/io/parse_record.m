function [tbl, isnum, orig_fn] = parse_record(tbl_file, varargin)
% PARSE_RECORD Read a text table as a structure array.
%   TBL = PARSE_RECORD(TBLFILE) Reads a tab delimited text file and returns
%   a structure array with one record per line in the file with fields
%   named according to the headers provided in the file. This is 
%   convenience function that is equivalient to:
%       PARSE_TBL(FILE, 'outfmt', 'record')
%   TBL = PARSE_RECORD(TBLFILE, 'param', value,...) Specify optional
%   parameters.
% 
% See PARSE_TBL for details

[tbl, isnum, orig_fn] = parse_tbl(tbl_file, varargin{:}, 'outfmt', 'record');

end