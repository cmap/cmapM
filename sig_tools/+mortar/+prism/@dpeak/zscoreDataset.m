function zs = zscoreDataset(ds)
% ds is dpeaked  dataset

zs = ds;
zs.mat = robust_zscore(safe_log2(zs.mat), 2,...
                        'var_adjustment', 'fixed',...
                        'min_mad', 0.1);
zs.mat = clip(zs.mat, -10, 10);
end