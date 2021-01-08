function [desc, hd] = del_annot(desc, hd, fn)

k = hd.keys;
v = cell2mat(hd.values);
revidx = containers.Map(v, k);
delidx = cell2mat(hd.values(fn));
desc(:, delidx) = [];

revidx.remove(delidx);
[~, stridx] = sort(cell2mat(revidx.keys));
newk = revidx.values;
hd = containers.Map(newk(stridx), 1:revidx.length);