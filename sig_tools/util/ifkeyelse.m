function x = ifkeyelse(d, k, miss)
% IFKEYELSE Ternary operator to check if key exists in dictionary

if d.isKey(k)
    x = d(k);
else
    x = miss;
end
end