function tbl = gmt2tbl(gmt)
% GMT2TBL Convert geneset(s) to table.
% T = GMT2TBL(
if isfileexist(gmt)
    gmt = parse_geneset(gmt);
elseif ~isstruct(gmt)
    error('File not found');
end

ns = length(gmt);
ng = sum([gmt.len]);

tbl = struct('group_id', cell(ng, 1),...
             'group_size', nan,...
             'desc', '', 'member_id', '');
ctr = 0;
for ii=1:ns
    n = gmt(ii).len;
    [tbl(ctr+(1:n)).group_id] = deal(gmt(ii).head);
    [tbl(ctr+(1:n)).group_size] = deal(n);
    [tbl(ctr+(1:n)).desc] = deal(gmt(ii).desc);
    [tbl(ctr+(1:n)).member_id] = gmt(ii).entry{:};
    ctr = ctr + n;
end

end