function [h, quad] = plot_rc(cc, rnk, varargin)
% PLOT_RC Display self-rank correlation plot.

pnames = {'group', 'rnk_cutoff', 'cc_cutoff', 'showfig',...
    'perm_stat', 'use_std_color', 'legend_location'};
dflts = {'', 5, 0.2, true,...
    '', true, 'east'};
args = parse_args(pnames, dflts, varargin{:});

rnk = rnk(:);
cc = cc(:);

myfigure(args.showfig);
hits = rnk <= args.rnk_cutoff & cc >= args.cc_cutoff;
n = length(rnk);
nhit = nnz(hits);
pcthit = 100* nhit / length(hits);
plot([-1 1], args.rnk_cutoff*ones(2,1), '--', 'color', get_color('grey'), 'linewidth', 2)
hold on
plot(args.cc_cutoff*ones(2,1), [0 100], '--', 'color', get_color('grey'), 'linewidth', 2)

if ~isempty(args.group);
    gp = args.group(:);
    [h, lh, gn] = gpscatter(cc, rnk, gp, 'size', 7, 'location', args.legend_location);
    if args.use_std_color
        [rgb, sym, isfilled] = get_type_attr(gn);
        set_attr(h, rgb, sym, isfilled, 7);
    end
    set(lh,'fontsize',10, 'box', 'off');
else
    h = scatter(cc, rnk);
end

text(-0.95, double(args.rnk_cutoff), stringify(args.rnk_cutoff, 'fmt','%1.2g'),...
    'color', 'r', 'fontsize', 10, 'fontweight','bold',...
    'verticalalignment','bottom')
text(double(args.cc_cutoff)+0.01, 99, stringify(args.cc_cutoff, 'fmt','%1.2g'), ...
    'color', 'r', 'fontsize', 10, 'fontweight','bold',...
    'horizontalalignment', 'left')

quad = get_sc_quad(rnk, cc, args.rnk_cutoff, args.cc_cutoff);
% add percent counts in each quad
text(-.9, 1, sprintf('%.1f%%', quad.bot_left), 'fontsize', 20);
text(.6, 1, sprintf('%.1f%%', quad.bot_right), 'fontsize', 20);
text(-.9, 90.5, sprintf('%.1f%%', quad.top_left), 'fontsize', 20);
text(.6, 90.5, sprintf('%.1f%%', quad.top_right), 'fontsize', 20);

% scatter(cc(hits), rnk(hits), 'r.');
title(sprintf('n: %d nhits:%d [%2.1f%%]',n, nhit, pcthit));
xlabel('Spearman Q75')
ylabel('% Self Rank Q25')
xlim([-1 1])
ylim([0 100])
end
