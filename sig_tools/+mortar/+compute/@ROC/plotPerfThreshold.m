function hf_perf = plotPerfThreshold(roc_rpt, roc_summary)
% Merics vs Threshold plot
hf_perf = figure;
ntrue = roc_summary.ntrue;
nfalse = roc_summary.nfalse;

th = [roc_rpt.th]';
fpr = [roc_rpt.fpr]';
tpr = [roc_rpt.tpr]';
ppv = [roc_rpt.ppv]';
npv = [roc_rpt.npv]';
yj = [roc_rpt.yj]';
f1 = [roc_rpt.f1]';

plot(th, [tpr, fpr, ppv, yj, f1], 'linewidth',2)
legend({'TPR', 'FPR', 'PPV', 'TPR-FPR', 'F1'},'location','northeast')
xlabel(texify(sprintf('Threshold')))
title(sprintf('nT:%d nF:%d', ntrue, nfalse));
xlim([0 max(th)]);
ylim([0, 1]);
namefig('perf_vs_threshold');
end