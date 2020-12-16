function [hf, recall_summary] = plotPerSet(set_recall_rpt, well_field, varargin)
% plotPerSet Display diagnostic plots for replicate sets

pnames = {'--showfig', '--ylabelrt'};
dflts = {true, ''};
help_str = {'boolean, Hide figure if false',...
            'string, Right sided Y-axis label'};
config = struct('name', pnames,...
            'default', dflts,...
            'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Display diagnostic plots for replicate sets');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});


recall_metric = set_recall_rpt(1).recall_metric;
recall_score = [set_recall_rpt.median_recall_score]';
recall_rank = [set_recall_rpt.median_recall_rank]';
recall_composite = [set_recall_rpt.median_recall_composite]';
recall_max_rank = [set_recall_rpt.median_max_rank]';
pct_rank = 100*recall_rank ./ recall_max_rank;
npoints = length(recall_score);

% 1, 5, 10% thresholds for fr_ranks
pct_rank_stats = describe(pct_rank);
n_1pct = nnz(pct_rank<=1);
n_5pct = nnz(pct_rank<=5);
n_10pct = nnz(pct_rank<=10);

% fr_rank_th = [1;5;10] / 100;
% [f_rank, x_rank] = ecdf(fr_rank);
% [f_rank_th, rank_label] = get_cdf_values(x_rank, f_rank, fr_rank_th);

num_plots = 3;
if ~isempty(well_field) && isfield(set_recall_rpt, well_field)
    well_name = {set_recall_rpt.(well_field)}';
    to_make_platemap = true;
    num_plots = num_plots + 1;
else
    to_make_platemap = false;
end

recall_summary = struct('npoints', npoints,...
       'nrecall_1pct', n_1pct,...
       'nrecall_5pct', n_5pct,...
       'nrecall_10pct', n_10pct);

hf = nan(num_plots, 1);

% Sep13, 2018 Deprecated since ranks are in percentile scale
% % distribution of Percentile ranks
% hf(1) = myfigure(args.showfig);
% [hf1_l2, hf1_l1] = plot_cdfhist(pct_rank, 30);
% set(hf1_l2, 'linewidth', 2, 'color', get_color('scarlet'));
% set(hf1_l1, 'facecolor', ones(1,3)*0.7)
% xlabel('Median Recall Rank')
% xlim([0 1])
% if ~isempty(args.ylabelrt)
%     ylabelrt(texify(args.ylabelrt), 'color', 'b');
% end
% namefig('cdf_set_recall_pct_rank');

% distribution of recall Score
hf(1) = myfigure(args.showfig);
[hf1_l2, hf1_l1] = plot_cdfhist(recall_score, 30);
set(hf1_l2, 'linewidth', 2, 'color', get_color('ochre'));
set(hf1_l1, 'facecolor', ones(1,3)*0.7)
xlim([-1, 1]);
xlabel('Median Recall Score')
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end
namefig('cdf_set_recall_score');

% distribution of recall ranks
hf(2) = myfigure(args.showfig);
[hf2_l2, hf2_l1] = plot_cdfhist(recall_rank, 30);
set(hf2_l2, 'linewidth', 2, 'color', get_color('indigo'));
set(hf2_l1, 'facecolor', ones(1,3)*0.7)
xlim([0, 100]);
xlabel('Median Recall Rank')
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end
namefig('cdf_set_recall_rank');

% distribution of Composite scores
hf(3) = myfigure(args.showfig);
[hf3_l2, hf3_l1] = plot_cdfhist(recall_composite, 30);
set(hf3_l2, 'linewidth', 2, 'color', get_color('forest'));
set(hf3_l1, 'facecolor', ones(1,3)*0.7)
xlabel('Median Composite Score')
xlim([0 1])
if ~isempty(args.ylabelrt)
    ylabelrt(texify(args.ylabelrt), 'color', 'b');
end
namefig('cdf_set_recall_composite');

if to_make_platemap
    % platemap    
    clr_ax = [0, 0.5];
    clr_map = ctgmap;
    clr_map = clr_map(1:7:end, :);
    title_str = sprintf('n=%d 1%%:%d 5%%:%d 10%%:%d',...
        pct_rank_stats.n,...
        n_1pct,...
        n_5pct,...
        n_10pct);
    hf(5) = plot_platemap(pct_rank, well_name,...
        'name', 'platemap_set_recall_fr_rank',...
        'title', title_str,...
        'caxis', clr_ax,...
        'ylabelrt', args.ylabelrt,...
        'showfig', args.showfig);
    colormap(clr_map);
end

end