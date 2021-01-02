function [perf_rpt, perf_summary, hf_roc, hf_perf] = roc_perfomance(labels, scores)
% ROC_PERFORMANCE Perform ROC analysis
% [RPT, SUMMARY, HFROC, HFPERF] = ROC_PERFORMANCE(L, S)

[fpr, tpr, th, auc] = perfcurve(labels, scores, true);
ntrue = nnz(labels);
nfalse = nnz(~labels);
tp = tpr*ntrue;
fp = fpr*nfalse;
tn = nfalse-fp;
fn = ntrue - tp;
% precision (Postive Predictive Value)
ppv = tp./(tp+fp);
% Negative predictive value
npv = tn./(tn+fn);
% Youdens J-statistic, Bookmaker Informedness: 
yj = tpr-fpr;
% F-score
f1 = 2*((ppv .* tpr)./(ppv + tpr));
% F2 measure weighs recall higher than precision 
% (by placing more emphasis on false negatives)
f2 = 5*((ppv .* tpr)./(4*ppv + tpr));
% F0.5 measure, weighs recall lower than 
% precision (by attenuating the influence of false negatives).
fp5 = 2.25*((ppv .* tpr)./(0.25*ppv + tpr));

xq = linspace(min(th), max(th), 201)';

f2_int = interp1(th(2:end), f2(2:end), xq, 'linear');
f1_int = interp1(th(2:end), f1(2:end), xq, 'linear');
fp5_int = interp1(th(2:end), fp5(2:end), xq, 'linear');
yj_int = interp1(th(2:end), yj(2:end), xq, 'linear');

tpr_int = interp1(th(2:end), tpr(2:end), xq, 'linear');
fpr_int = interp1(th(2:end), fpr(2:end), xq, 'linear');
ppv_int = interp1(th(2:end), ppv(2:end), xq, 'linear');
npv_int = interp1(th(2:end), npv(2:end), xq, 'linear');

[max_f1, max_idx] = nanmax(f1_int);
max_f2 = f2_int(max_idx);
max_fp5 = fp5_int(max_idx);
max_yj = yj_int(max_idx);
max_th = xq(max_idx);
max_tpr = tpr_int(max_idx);
max_fpr = fpr_int(max_idx);
max_ppv = ppv_int(max_idx);
max_npv = npv_int(max_idx);

perf_rpt = struct('th', num2cell(th),...
                  'fpr', num2cell(fpr),...
                  'tpr', num2cell(tpr),...
                  'ppv', num2cell(ppv),...
                  'npv', num2cell(npv),...
                  'jstat', num2cell(yj),...
                  'f1', num2cell(f1),...
                  'f2', num2cell(f2),...
                  'fp5', num2cell(fp5));

perf_summary = struct('auc_roc', auc,...
                      'ntrue', ntrue,...
                      'nfalse', nfalse,...
                      'max_f1', max_f1,...
                      'max_f2', max_f2,...
                      'max_fp5', max_fp5,...
                      'max_jstat', max_yj,...
                      'max_tpr', max_tpr,...
                      'max_fpr', max_fpr,...
                      'max_ppv', max_ppv,...
                      'max_npv', max_npv,...
                      'best_th', max_th);                  
                  
% ROC curve
hf_roc = figure;
stairs(fpr,tpr, 'linewidth', 2)
axis square
xlabel('FPR')
ylabel('TPR')
hold on
plot([0, 1], [0, 1], 'k--')
title(sprintf('AUC: %2.2f', auc));
namefig('roc');

% Merics vs Threshold plot
hf_perf = figure;
%plot(th, [tpr, fpr, ppv, tpr-fpr, tpr-ppv], 'linewidth',2)
%plot(th, [tpr, fpr, ppv, npv, tpr-fpr, f1], 'linewidth',2)
plot(xq, [tpr_int, fpr_int, ppv_int, npv_int, tpr_int-fpr_int, f1_int], 'linewidth',2)
hold on
plot_constant(max_th, false, 'k--')
plot(max_th, max_f1, 'ko', 'markerfacecolor', 'r')
legend({'Recall (TPR)', 'FPR', 'Precision (PPV)', 'NPV', 'TPR-FPR', 'F1'},'location','northeast')
xlabel(texify(sprintf('Threshold')))
title(sprintf('nT:%d nF:%d', ntrue, nfalse));
xlim([min(th) max(th)]);
ylim([0, 1]);
namefig('perf_vs_threshold');

end