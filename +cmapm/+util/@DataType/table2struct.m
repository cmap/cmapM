function s = table2struct(tbl, hdr)
% TABLE2STRUCT Convert cell with headers to a structure.
%   S = TABLE2STRUCT(TBL, HDR)
s = cell2struct(tbl, hdr, 2);

end