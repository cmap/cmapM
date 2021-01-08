function [h, recall_summary] = plotRecall(rpt, varargin)
% plotRecall Generate diagnostic plots for recall analysis
%   [H, RPT] = plotRecall(RPT, SHOWFIG) RPT is the result returned by
%   the computeRecall method. SHOWFIG is a boolean which hides figures if
%   false. RPT is a structure with summary statistics

pnames = {'--showfig', '--ylabelrt'};
dflts = {true, ''};
help_str = {'boolean, Hide figure if false',...
            'string, Right sided Y-axis label'};
config = struct('name', pnames,...
            'default', dflts,...
            'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Generate diagnostic plots for recall analysis');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});


recall_metric = rpt(1).recall_metric;
recall_score = [rpt.recall_score]';
recall_rank = [rpt.recall_row_rank]';
recall_composite = [rpt.recall_composite]';
max_col_rank = rpt(1).max_col_rank;
max_row_rank = rpt(1).max_row_rank;
max_rank = rpt(1).max_row_rank;

col_rank = [rpt.recall_col_rank]';
row_rank = [rpt.recall_row_rank]';
npoints = length(recall_score);

% 1, 5, 10% thresholds for ranks
rank_th = round([1;5;10] * max_rank / 100);
col_rank_th = round([1;5;10] * max_col_rank / 100);
row_rank_th = round([1;5;10] * max_row_rank / 100);

[f_rank, x_rank] = ecdf(recall_rank);
[f_rank_th, rank_label] = get_cdf_values(x_rank, f_rank, rank_th);

[f_col_rank, x_col_rank] = ecdf(col_rank);
[f_col_rank_th, col_rank_label] = get_cdf_values(x_col_rank, f_col_rank, col_rank_th);

[f_row_rank, x_row_rank] = ecdf(row_rank);
[f_row_rank_th, row_rank_label] = get_cdf_values(x_row_rank, f_row_rank, row_rank_th);

recall_summary = struct('npoints', npoints,...        
       'max_rank', max_rank,...
       'rank_thresh_1pct', rank_th(1),...
       'rank_1pct', f_rank_th(1),...
       'rank_thresh_5pct', rank_th(2),...
       'rank_5pct', f_rank_th(2),...
       'rank_thresh_10pct', rank_th(3),...
       'rank_10pct', f_rank_th(3));

% Scatter of score vs rank
h1 = myfigure(args.showfig);
%jitter_rank = clip(jitter(recall_rank, 'amount', 0.5), 1, inf);
scatter(recall_rank, recall_score, 25, recall_composite, 'o');
set(gca,'yscale','linear','xscale','log');
axis tight
title(sprintf('n=%d', npoints));
xlabel(sprintf('Log Recall Rank (max=%d)', max_rank));
ylabel(sprintf('Recall Score (%s)', recall_metric));
%ylim([-1, 1]);
colorbar
caxis([0 1]);
colormap(flipud(parula(10)))
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end
namefig('score_vs_log_rank');

% CDF of recall rank
h2 = myfigure(args.showfig);
[h2_hc, h2_hh] = plot_cdfhist(recall_rank, 30);
plot(rank_th, f_rank_th, 'o',...
     'markerfacecolor', ones(3,1)*0.6, 'markeredgecolor', 'k');
text(double(rank_th), double(f_rank_th-0.02), rank_label);
set(h2_hc, 'linewidth', 2);
set(h2_hh, 'facecolor', ones(1,3)*0.6);
set(gca, 'yscale', 'linear', 'xscale', 'linear');
axis tight
ylim([0, 1]);
title(sprintf('n=%d', npoints));
xlabel(sprintf('Recall Rank (max=%d)', max_rank));
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end
namefig('cdf_rank');

% CDF of recall scores
h3 = myfigure(args.showfig);
[h3_hc, h3_hh] = plot_cdfhist(recall_score, 30);
set(h3_hc, 'linewidth', 2);
set(h3_hh, 'facecolor', ones(1,3)*0.6);
set(gca,'yscale','linear','xscale','linear');
axis tight
ylim([0, 1]);
xlim([-1, 1]);
title(sprintf('n=%d', npoints));
xlabel(sprintf('Recall Score (%s)', recall_metric));
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end
namefig('cdf_score');

% CDF of recall composite score
h4 = myfigure(args.showfig);
[h4_hc, h4_hh] = plot_cdfhist(recall_composite, 30);
set(h4_hc, 'linewidth', 2);
set(h4_hh, 'facecolor', ones(1,3)*0.6);
set(gca, 'yscale', 'linear', 'xscale', 'linear');
axis tight
ylim([0, 1]);
xlim([0, 1]);
title(sprintf('n=%d', npoints));
xlabel('Recall Composite Score');
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end
namefig('cdf_composite');

% % CDF of Row ranks
% myfigure(show_figure, h(4));
% hp4 = stairs(x_row_rank, f_row_rank);
% hold on
% plot(row_rank_th, f_row_rank_th, 'o', 'markerfacecolor', ones(3,1)*0.6, 'markeredgecolor', 'k');
% text(double(row_rank_th), double(f_row_rank_th-0.02), row_rank_label);
% %set(hp4, 'linewidth', 2, 'color', get_color('forest'));
% set(hp4, 'linewidth', 2);
% set(gca,'yscale','linear','xscale','log');
% axis tight
% ylim([0, 1]);
% title(sprintf('n=%d', npoints));
% xlabel(sprintf('Log Row Rank (max=%d)', max_row_rank));
% namefig('cdf_log_rowrank');

h = [h1; h2; h3; h4];
end
