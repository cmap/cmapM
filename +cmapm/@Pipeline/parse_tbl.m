function tbl = parse_tbl(tblfile, varargin)
% PARSE_TBL Read a text table.
%   TBL = PARSE_TBL(TBLFILE) Returns a structure TBL with fieldnames set 
%   to header labels in row one of the table.
%
%   TBL = PARSE_TBL(TBLFILE, param1, value1,...) Specifies optional
%   parameters and values. Valid parameters are:
%   'outfmt' <String> Output format. Valid options are
%       {'column','record','dict'}. Default is 'column'
%   'numhead' <Integer> Number of lines to skip. Specifies the row
%   	where the data begins. Assumes the fieldnames are at
%   	(numhead-1)th row. Default is 1. 
%   'lowerhdr' <boolean> Convert header to lowercase. Default is True
%   'detect_numeric' <boolean> Convert numeric fields to
%   	double. Default is True. 
%   'ignore_hash' <boolean> Ignore filds that begin with a
%   	hash. Default is True.


tbl = parse_tbl(tblfile, varargin{:});

end
