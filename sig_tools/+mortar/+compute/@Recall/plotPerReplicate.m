function h = plotPerReplicate(rep_recall_rpt, varargin)
% plotPerReplicate Generate per replicate recall plots
% h = plotPerReplicate(recall_rpt, showfig)

pnames = {'--showfig', '--ylabelrt'};
dflts = {true, ''};
help_str = {'boolean, Hide figure if false',...
            'string, Right sided Y-axis label'};
config = struct('name', pnames,...
            'default', dflts,...
            'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Generate per replicate recall plots');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});


recall_metric = rep_recall_rpt(1).recall_metric;
recall_score = [rep_recall_rpt.recall_score]';
recall_rank = [rep_recall_rpt.recall_rank]';
recall_composite = [rep_recall_rpt.recall_composite]';
replicate_id = {rep_recall_rpt.replicate_id}';
replicate_name = {rep_recall_rpt.replicate_name}';
replicate_label = unique(replicate_name, 'stable');
replicate_label_tex = texify(replicate_label);
max_rank = rep_recall_rpt(1).max_rank;

h1 = myfigure(args.showfig);
boxplot(recall_score, replicate_id, 'orientation', 'horizontal', 'labels', replicate_label);
xlim([-1 1])
xlabel(sprintf('Recall Score (%s)', recall_metric))
set(findobj(gca, 'type', 'line'), 'linewidth', 2)
% if ~isempty(args.ylabelrt)
%     ylabelrt(texify(args.ylabelrt), 'color', 'b');
% end
namefig('boxplot_recall_score_by_replicate');

h2 = myfigure(args.showfig);
boxplot(recall_rank, replicate_id, 'orientation', 'horizontal', 'labels', replicate_label);
xlim([0 max_rank])
xlabel(sprintf('Recall Rank (%s)', recall_metric))
set(findobj(gca, 'type', 'line'), 'linewidth', 2)
namefig('boxplot_recall_rank_by_replicate');
% if ~isempty(args.ylabelrt)
%     ylabelrt(texify(args.ylabelrt), 'color', 'b');
% end

h3 = myfigure(args.showfig);
plot_gcdf(recall_score, replicate_id, 'labels', replicate_label_tex);
xlim([-1 1])
set(findobj(gca, 'type', 'line'), 'linewidth', 2)
xlabel(sprintf('Recall Score (%s)', recall_metric));
namefig('cdf_recall_score_by_replicate');
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end

h4 = myfigure(args.showfig);
plot_gcdf(recall_rank, replicate_id, 'labels', replicate_label_tex);
xlim([0 max_rank])
xlabel(sprintf('Recall Rank (%s)', recall_metric))
set(findobj(gca, 'type', 'line'), 'linewidth', 2)
namefig('cdf_recall_rank_by_replicate');
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end

h5 = myfigure(args.showfig);
boxplot(recall_composite, replicate_id, 'orientation', 'horizontal', 'labels', replicate_label);
xlim([0 1])
xlabel(sprintf('Recall Composite (%s)', recall_metric))
set(findobj(gca, 'type', 'line'), 'linewidth', 2)
namefig('boxplot_recall_composite_by_replicate');
% if ~isempty(args.ylabelrt)
%     ylabelrt(texify(args.ylabelrt), 'color', 'b');
% end

h6 = myfigure(args.showfig);
plot_gcdf(recall_composite, replicate_id, 'labels', replicate_label_tex);
xlim([0 1])
xlabel(sprintf('Recall Composite Score (%s)', recall_metric))
set(findobj(gca, 'type', 'line'), 'linewidth', 2)
namefig('cdf_recall_composite_by_replicate');
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end

h = [h1; h2; h3; h4; h5; h6];
end