function srthd = sorted_hd(hd)
% SORTED_HD Get keys of annotation header, sorted by index in desc.

k= hd.keys;
[~, srtidx] = sort (cell2mat(hd.values));
srthd = k(srtidx);