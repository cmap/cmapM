function v = idx2hd(hd, idx)
% IDX2HD Lookup key values from GCT v3 header.
revdict = revdict_hd(hd);
v = revdict.values(num2cell(idx));