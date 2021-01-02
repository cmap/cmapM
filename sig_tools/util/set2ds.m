function ds = set2ds(g)
% SET2DS Convert a set to a binary matrix
% DS = SET2DS(G)

g = parse_geneset(g);

cid = {g.head}';
cdesc = {g.desc}';
feature_space = setunion(g);

lut = mortar.containers.Dict(feature_space);
nr = length(feature_space);
nc = length(cid);
mat = zeros(nr, nc);
ridx = lut(cat(1, g.entry));
cidx = grpsize2idx([g.len]');
idx = sub2ind([nr, nc], ridx, cidx);
mat(idx) = 1;

ds = mkgctstruct(mat, 'rid', feature_space, 'cid', cid, 'cdesc', cdesc, 'chd', {'desc'});
end
