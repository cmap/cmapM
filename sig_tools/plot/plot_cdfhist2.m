function [hc, hh] = plot_cdfhist2(x1, x2, bins)
figure
[h1_hc, h1_hh] = plot_cdfhist(x1, bins);
xlim([-1, 1]);
yyaxis right
hold on
yyaxis left
hold on
[h2_hc, h2_hh] = plot_cdfhist(x2, bins);
xlim([-1, 1]);
col1 = get_color('scarlet');
col2 = get_color('blue');
set(h1_hc, 'color', col1, 'linewidth', 2, 'linestyle', '--');
set(h1_hh, 'facecolor', col1, 'edgecolor', 'none', 'facealpha', 0.5);
set(h2_hc, 'color', col2, 'linewidth', 2, 'linestyle', '--');
set(h2_hh, 'facecolor', col2, 'edgecolor', 'none', 'facealpha', 0.5);
hc = [h1_hc; h2_hc];
hh = [h1_hh; h2_hh];
axis tight
% xlabel('CC')
% title('Intra vs Inter Group Similarity')
% legend([h1_hh, h2_hh], {'Intra', 'Inter'}, 'location', 'northwest')
% namefig('inter_vs_intra_cc')
end