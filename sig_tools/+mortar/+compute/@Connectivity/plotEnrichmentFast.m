function hf = plotEnrichmentFast(es_max, es_running, rank_at_max, srt_rank, srt_wt, max_rank, is_weighted)
% plotEnrichmentFast Generate enrichment mountain plot for fastESCore
% outputs

G = length(srt_rank);
% full rank vector
x = 1:max_rank;
% Costs
if ~isequal(G, max_rank)
    missCost = -1/(max_rank - G);
else
    missCost = -1;
end

if (is_weighted)
    abs_wt = abs(srt_wt);
    hitCost = bsxfun(@rdivide, abs_wt, sum(abs_wt, 1));
else
    hitCost = 1/G;
end

y = ones(size(x))*missCost;
y(srt_rank) = hitCost;
y = cumsum(y);
y(srt_rank) = es_running;

hf = myfigure();
line_color = get_color('forest');
max_color = get_color('orange');
raster_color = get_color('scarlet');
plot(x, y, 'color', line_color, 'linewidth', 2 );
hold on
plot_constant(0, 'color', 'b', 'linestyle', ':', 'show_label', false);
xlim([1 max_rank])
hr = rasterplot(srt_rank, 1, max_rank, gca);
set(hr, 'color', raster_color, 'linewidth', 1)
ylim([-1, 1]);
xlabel ('Rank in Ordered Dataset');
ylabel ('Enrichment Score (ES)');
plot(rank_at_max, es_max, 'o', 'markerfacecolor', max_color);
text(double(rank_at_max) + 0.05, double(es_max + sign(es_max)*0.1), sprintf('%2.3f', es_max),...
    'color', 'b', 'fontsize', 14, 'fontweight', 'bold');

end