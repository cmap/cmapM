function [rpt, freq_ds, ov_ds] = getCellSetStats(gmt)

gmt = parse_geneset(gmt);

nset = length(gmt);
freq_ds = set_frequency(gmt);

ov = setoverlap(gmt);
ov_ds = hclust(ov);

set_sizes = [gmt.len]';
stat = describe(set_sizes);
nfeature = length(freq_ds.rid);

% range of set size
rpt = struct('num_set', nset,...
             'num_feature', nfeature,...
             'min_set_size', stat.min,...
             'max_set_size', stat.max,...
             'mean_set_size', stat.mean,...
             'median_set_size', stat.median,...
             'iqr_set_size', stat.iqr);
end