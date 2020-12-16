function mustat = avg_stats(stats)
% AVG_STATS Compute average stats for beadsets.
fn = fieldnames(stats(1));
nfn = length(fn);
mustat.sample = stats(1).sample;
for ii=1:nfn
    if isnumeric(stats(1).(fn{ii}))
        x = nanmean([stats(1).(fn{ii}), stats(2).(fn{ii})], 2);
        x(isnan(x) | isinf(x)) = 0;        
        mustat.(fn{ii}) = x;
    end
end
end