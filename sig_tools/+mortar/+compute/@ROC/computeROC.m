function [perf_rpt, perf_summary] = computeROC(varargin)
% computeROC Compute ROC on binary classification results

[args, help_flag] = getArgs(varargin{:});
if ~help_flag
    
    [perf_rpt, perf_summary] = getROC(args);
    
end
end

function [perf_rpt, perf_summary] = getROC(args)

data_struct = checkData(args);

ntrue = data_struct.ntrue;
nfalse = data_struct.nfalse;

% False and True positive rates
[fpr, tpr, th, auc] = perfcurve(args.labels, args.scores, args.pos_class);
% True positives
tp = tpr*ntrue;
% False positives
fp = fpr*nfalse;
% True negatives
tn = nfalse-fp;
% False negatives
fn = ntrue - tp;
% Precision or Positive predictive value
ppv = tp./(tp+fp);
% Negative predictive value
npv = tn./(tn+fn);

% F scores
% https://en.wikipedia.org/wiki/F1_score
f1 = mortar.compute.ROC.fscore(tpr, ppv, 1);
f2 = mortar.compute.ROC.fscore(tpr, ppv, 2);
fp5 = mortar.compute.ROC.fscore(tpr, ppv, 0.5);

% Youden's J statistic
% https://en.wikipedia.org/wiki/Youden%27s_J_statistic
yj = tpr - fpr;

% %
% xq = linspace(0, max(th), 201);
% yj_int = interp1(th(2:end), yj(2:end), xq, 'linear');
% [max_yj, max_idx] = nanmax(yj_int);
% max_yj_th = xq(max_idx);
[max_yj, max_yj_th] = getOptimalValue(th, yj);
[max_f1, max_f1_th] = getOptimalValue(th, f1);
[max_f2, max_f2_th] = getOptimalValue(th, f2);
[max_fp5, max_fp5_th] = getOptimalValue(th, fp5);

perf_rpt = struct('th', num2cell(th),...
    'tpr', num2cell(tpr),...
    'fpr', num2cell(fpr),...
    'ppv', num2cell(ppv),...
    'npv', num2cell(npv),...
    'f1', num2cell(f1),...
    'f2', num2cell(f2),...
    'fp5', num2cell(fp5),...
    'yj', num2cell(yj));

perf_summary = struct('auc_roc', auc,...
    'ntrue', ntrue,...
    'nfalse', nfalse,...
    'max_jstat', max_yj,...
    'max_jstat_th', max_yj_th,...
    'max_f1', max_f1,...
    'max_f1_th', max_f1_th,...
    'max_f2', max_f2,...
    'max_f2_th', max_f2_th,...
    'max_fp5', max_fp5,...
    'max_fp5_th', max_fp5_th);

end

function [max_y, max_th] = getOptimalValue(th, y)
xq = linspace(0, max(th), 201);
y_int = interp1(th(2:end), y(2:end), xq, 'linear');
[max_y, max_idx] = nanmax(y_int);
max_th = xq(max_idx);

end

function data_struct = checkData(args)

assert(mortar.util.Array.is1d(args.scores),...
    'Scores should be a one-dimensional vector');
assert(isa(args.scores, 'float'), 'Scores should be a floating point vector');
num_scores = length(args.scores);
num_labels = length(args.labels);
assert(isequal(num_labels, num_scores),...
    'Dimension mismatch for labels, expected %d elements got %d instead',...
    num_scores, num_labels);

[gp, gn, gl] = grp2idx(args.labels);
num_gp = length(gl);
assert(isequal(num_gp, 2),...
    'Labels should be a binary grouping variable, found %d groups instead',...
    num_gp);

dt_labels = class(args.labels);
dt_posclass = class(args.pos_class);
switch(dt_labels)
    case 'cell'
        dt_cell = class(args.labels{1});
        assert(isequal(dt_posclass, dt_cell),...
            'Class mismatch between Labels and Positive Class expected %s got %s instead',...
            dt_cell, dt_posclas)
        pos_idx = strcmp(gl, args.pos_class);
    otherwise
        % logical numeric class
        pos_idx = find(gl==args.pos_class);
        assert(isequal(length(pos_idx),1), 'Positive class not found');
end

bin_labels = gp == pos_idx;
ntrue = nnz(bin_labels);
nfalse = num_labels - ntrue;

data_struct = struct('ntrue', ntrue,...
    'nfalse', nfalse);
end

function scratch
% groundtruth labels based on Pr500 @120h
kill_thresh = 30;
gtruth = [score_tbl.pr500_ss_ltn2_120h]';
labels = gtruth>=kill_thresh;

pert_itime = {score_tbl.pert_itime}';
score_field = 'cop_hm_activity';
scores = [score_tbl.(score_field)]';

[ctime, itime] = getcls(pert_itime);
ntime = length(ctime);

leg_label = cell(ntime, 1);
for ii=1:ntime
    this = itime==ii;
    this_score = scores(this);
    this_label = labels(this);
    ntrue = nnz(this_label);
    nfalse = nnz(~this_label);
    [fpr, tpr, th, auc] = perfcurve(this_label, this_score, true);
    tp = tpr*ntrue;
    fp = fpr*nfalse;
    tn = nfalse-fp;
    fn = ntrue - tp;
    % precision
    ppv = tp./(tp+fp);
    % negative predictive value
    npv = tn./(tn+fn);
    figure(1)
    stairs(fpr,tpr, 'linewidth', 2)
    hold on
    leg_label{ii} = sprintf('%s nT:%d nF:%d AUC:%2.2f', ctime{ii}, ntrue, nfalse, auc);
    
    figure
    %plot(th, [tpr, fpr, ppv, tpr-fpr, tpr-ppv], 'linewidth',2)
    plot(th, [tpr, fpr, ppv, npv, tpr-fpr], 'linewidth',2)
    legend({'TPR', 'FPR', 'PPV', 'NPV', 'TPR-FPR'},'location','northeast')
    xlabel(texify(sprintf('%s Threshold', score_field)))
    title(sprintf('%s nT:%d nF:%d', ctime{ii}, ntrue, nfalse));
    xlim([0 max(th)]);
    ylim([0, 1]);
    namefig(lower(sprintf('perf_vs_th_%s_%s', ctime{ii}, score_field)));
end
figure(1)
axis square
xlabel('FPR')
ylabel('TPR')
legend([leg_label;{'Identity'}], 'location', 'southeast')
plot([0, 1], [0, 1], 'k--')
title(sprintf('Prism activity threshold >=%d cell lines', kill_thresh))
namefig(sprintf('roc_%s', score_field));
end

function [args, help_flag] = getArgs(varargin)
config = struct('name',...
    {'--scores';...
    '--labels';...
    '--pos_class';...
    },...
    'default', {[];...
    [];...
    true},...
    'help', {'Floating point vector representing classifier prediction scores';...
    'Binary grouping variable (numeric, logical or cell array of strings) of the same dimension as scores';...
    'Scalar of the same datatype as labels, representing the positive class'});
opt = struct('prog', mfilename, 'desc', 'Compute Receiver Operating Characteristic for classifier input');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
end
