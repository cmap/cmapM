function plot_es(res, hitrank)

N = length(res);

figure
plot(1:N, res, 'g', 'linewidth', 2 );
hold on
plot_constant(0);
xlim([1 N])
rasterplot(hitrank,1,N,gca);
ylim([-1 1]);
xlabel ('Rank in Ordered Dataset');
ylabel ('Enrichment Score (ES)');
[absmax, maxidx] = max(abs(res));
es_max = absmax.*sign(res(maxidx));
title(sprintf('ES: %2.3f', es_max));
end