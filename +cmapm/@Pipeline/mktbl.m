function mktbl(outfile, tbl, varargin)
% MKTBL Create a delimted text table.
%   MKTBL(OUTFILE, TBL) Creates tab delimited text file OUTFILE. TBL can be
%   a structure or a cell array. Two types of structures are supported. TBL
%   can be single structure where each fieldname comprised a cell array of
%   length equal to the number of rows in the table. Alternatively TBL can
%   be a a 1D structure array of length equal to the number of rows in the
%   table and each element having the same fieldnames. TBL can also be a 2D
%   cell array. 
%
%   MKTBL(OUTFILE, TBL, param1, value1,...). Specify optional parameters:
%   'precision': scalar integer, precision of numeric values. Default is
%       INF where the precision is selected automatically.
%   'dlm': string, delimiter. Default is '\t'
%   'emptyval': string, Substitution for empty values. Default is ''
%   'header': cell array, Alternate fieldnames, length must equal number of
%       fields in the table. If TBL is a cell array, the fieldnames are
%       auto generated if header is not specified.

mktbl(outfile, tbl, varargin{:});

end

