function idx = hd2idx(hd, v)
% HD2IDX Lookup indices for GCT v3 headers.

if ischar(v)
    v = {v};
end
iskey = hd.isKey(v);

if all(iskey)
    idx = cell2mat(hd.values(v));
else    
    disp (v(~iskey))    
    error('specified key(s) not present');
end