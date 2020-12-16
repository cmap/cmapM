function revdict = revdict_hd(hd)

k = hd.keys;
v = cell2mat(hd.values);
revdict = containers.Map(v, k);