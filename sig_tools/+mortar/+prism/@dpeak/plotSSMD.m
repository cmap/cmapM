function plotSSMD(rpt, varargin)
% Plot SSMD stats
config = struct('name', {'--showfig';'--title_prefix'},...
              'default', {true; 'PLATE_XXX'},...
              'help', {'Display figure if true'; 'Title prefix'});

opt = struct('prog', mfilename, 'desc', 'Plot SSMD statistics');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

det_mode_orig = {rpt.det_mode};
[~, ord] = sort(det_mode_orig);
rpt = rpt(ord(end:-1:1));
det_group = get_groupvar(rpt, fieldnames(rpt), {'det_mode', 'det_pool'});
det_group = strrep(det_group, 'uni:low', 'uni');
det_mode = {rpt.det_mode}';
det_pool = {rpt.det_pool}';

is_uni = strcmp(det_group, 'uni');
is_duo = strcmp(det_mode, 'duo');
is_duo_high = strcmp(det_group, 'duo:high');
is_duo_low = strcmp(det_group, 'duo:low');
ssmd = [rpt.ssmd]';
ssmd_thresh = 1.5;

nuni = nnz(is_uni);
nduo_high = nnz(is_duo_high);
nduo_low = nnz(is_duo_low);

uni_median = median(ssmd(is_uni));
duo_high_median = median(ssmd(is_duo_high));
duo_low_median = median(ssmd(is_duo_low));

pct_uni_fail = 100*nnz(ssmd(is_uni) < ssmd_thresh)/nuni;
pct_duo_high_fail = 100*nnz(ssmd(is_duo_high) < ssmd_thresh)/nduo_high;
pct_duo_low_fail = 100*nnz(ssmd(is_duo_low) < ssmd_thresh)/nduo_low;

uni_label = sprintf ('Uni (n=%d)', nuni);
duo_high_label = sprintf ('Duo:high (n=%d)', nduo_high);
duo_low_label = sprintf ('Duo:low (n=%d)', nduo_low);

%% SSMD boxplots
figure
hb = boxplot(ssmd, det_group,...
        'grouporder', {'uni', 'duo:high', 'duo:low'},...
        'labels', {uni_label, duo_high_label, duo_low_label});
hl = plot_constant(ssmd_thresh, true, 'linestyle', '--','color', get_color('grey'));
title('SSMD by detection mode')
grid off
th_uni = text(1, 6.5, sprintf('Fail: %2.1f%%', pct_uni_fail));
th_duohi = text(2, 6.5, sprintf('Fail: %2.1f%%', pct_duo_high_fail));
th_duolo = text(3, 6.5, sprintf('Fail: %2.1f%%', pct_duo_low_fail));
set([th_uni, th_duohi, th_duolo], 'horizontalalignment', 'center',...
    'color', get_color('scarlet'))
ylabelrt(texify(args.title_prefix));
namefig('ssmd_by_det_mode');
ylim([0 7])
ylabel('SSMD')

%% SSMD per analyte
figure
trace = repmat(ssmd, 1, 3);
trace(is_duo, 1) = nan;
trace(~is_duo_high, 2) = nan;
trace(~is_duo_low, 3) = nan;
plot(trace);
xlim([1 numel(ssmd)]);
ylim([0 6]);
xlabel('Analytes');
ylabel('SSMD');
plot_constant(ssmd_thresh, true, 'linestyle', '--','color', get_color('grey'));
legend({'Uni', 'Duo:High', 'Duo:Low'});
ylabelrt(texify(args.title_prefix));
namefig('ssmd_by_analyte');

end