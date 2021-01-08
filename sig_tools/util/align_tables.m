function [a1,a2] = align_tables(tbl1,tbl2,hd)
% ALIGN_TABLES reorders tables TBL1, TBL2 so the HD fields match
% [A1, A2] = ALIGN_TABLES(TBL1, TBL2, HD

tbl1 = parse_tbl(tbl1,'outfmt','record');
tbl2 = parse_tbl(tbl2,'outfmt','record');

% get HD field
assert(isfield(tbl1,hd) & isfield(tbl2,hd), sprintf('%s is invalid field name',hd));
hd1 = {tbl1.(hd)};
hd2 = {tbl2.(hd)};


if isnumeric(hd1{1})
    hd1 = [hd1{:}];
    hd2 = [hd2{:}];
end

% check for unique identifiers
assert(isunique(hd1) & isunique(hd2),sprintf('%s entries must be unique',hd));

% check that entries of HD field are the same in both tables
assert(isequal(length(union(hd1,hd2)), length(hd1), length(hd2)),...
    sprintf('%s entry mismatch',hd));

[~,t1_idx] = sort(hd1);
[~,t2_idx] = sort(hd2);

a1 = tbl1(t1_idx);
a2 = tbl2(t2_idx);