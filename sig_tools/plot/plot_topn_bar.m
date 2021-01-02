function [bh, th] = plot_topn_bar(x, n, xlab)

[topn, itop] = get_topn(x, n, 1, 'descend', true);

pos_color = [0.7882, 0.1765, 0.0392];
neg_color = [0.1216, 0.4667, 0.7059];
bar_color = zeros(length(topn), 3);
is_pos = topn>0;
is_neg = topn<=0;
bar_color(is_neg, :) = repmat(neg_color, nnz(is_neg), 1);
bar_color(is_pos>0, :) = repmat(pos_color, nnz(is_pos), 1);

bh = barh(topn, 'barwidth', 0.6);
set(bh,'facecolor', 'flat',  'Cdata', bar_color)
nudge = double(0.01*range(x) * sign(topn));
%nudge = -0.02;
th = text(double(topn)+nudge, 1:length(topn), xlab(itop), 'fontsize', 10, 'units', 'data');
axis ij
set(th(is_neg),'HorizontalAlignment', 'right', 'color', neg_color);
set(th(is_pos),'HorizontalAlignment', 'left', 'color', pos_color);

xl = get(gca, 'xlim');
xl_nudge = 0.05*range(xl);
xlim([xl(1)-xl_nudge, xl(2)+xl_nudge])

end