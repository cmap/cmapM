function hf_roc = plotROC(roc_rpt, roc_summary)
% ROC curve
fpr = [roc_rpt.fpr]';
tpr = [roc_rpt.tpr]';
auc_roc = roc_summary.auc_roc;

hf_roc = figure;
stairs(fpr, tpr, 'linewidth', 2)
axis square
xlabel('FPR')
ylabel('TPR')
hold on
plot([0, 1], [0, 1], 'k--')
title(sprintf('AUC-ROC: %2.2f', auc_roc));
namefig('roc');

end