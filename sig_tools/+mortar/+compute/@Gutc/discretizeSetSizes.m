function [set_size_forperm, set_size_gpidx] = discretizeSetSizes(set_sizes, num_freq_sets, num_binned_sets)
% discretizeSetSizes discretize the set sizes to reduce the number of permutations
% [set_size_forperm, set_size_gpidx] = discretizeSetSizes(set_sizes, num_freq_sets, num_binned_sets)
% num_freq_sets sets to include based on frequency
% num_binned_sets sets to include by histogram binning

size_rpt = tally(set_sizes, false);
set_stats_raw = describe([size_rpt.group_size]');
num_sets_raw = set_stats_raw.n;
% sets to include based on frequency
num_freq_sets = clip(num_freq_sets, 1, num_sets_raw);
% sets to include by histogram binning
num_binned_sets = clip(num_binned_sets, 1, num_sets_raw);
[~, sort_idx] = sort([size_rpt.group_size]', 'descend');
sort_size = [size_rpt(sort_idx).group]';
[n, b] = hist(sort_size(num_freq_sets + 1:end), num_binned_sets);
bins = union(sort_size(1:num_freq_sets), round(b));

% map set_size to nearest selected set_size bin
[set_size_nn, bidx] = discretize(set_sizes, bins);
[bin_gp, set_size_gpidx] = getcls(bidx);
set_size_forperm = bins(bin_gp);

% number of set-sizes to compute
set_stats_forperm = describe(set_size_forperm);
num_sets_forperm = set_stats_forperm.n;

dbg(1, '# %d unique set sizes found', num_sets_raw);
dbg(1, '# min:%d, max:%d, mean:%2.0f, median:%d', set_stats_raw.min, set_stats_raw.max, set_stats_raw.mean, set_stats_raw.median);
top_set_size_tbl = struct2table(size_rpt(sort_idx(1:clip(10, 1, num_sets_raw))));
dbg(1, '# %d most frequent set sizes:', size(top_set_size_tbl, 1))
disp(top_set_size_tbl);
dbg(1, '# %d sets selected for permutations from %d frequent and %d histogram-binned sizes', num_sets_forperm, num_freq_sets, num_binned_sets);
dbg(1, '# min:%d, max:%d, mean:%2.0f, median:%d', set_stats_forperm.min, set_stats_forperm.max, set_stats_forperm.mean, set_stats_forperm.median);

end