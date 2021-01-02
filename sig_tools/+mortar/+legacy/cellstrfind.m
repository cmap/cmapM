function idx = cellstrfind(cs, s)

m = strcmp(s, cs);
idx = find(m);