function ds = mkgctstruct(mat, varargin)
% MKGCTSTRUCT Create a gct data structure.
% DS = MKGCTSTRUCT('name1', 'value1', ...)
%   'mat': numeric data matrix
%   'rid': Row identifiers, cell array. Length must equal size(mat, 1).
%   'cid': Column identifiers, cell array. Length must equal size(mat, 2).
%   'rhd': Row header
%   'rdesc': Row descriptors
%   'chd': Column header
%   'cdesc': Column descriptors
%   'src': Source name

ds = mkgctstruct(mat, varargin{:});

end