function all_qvals = fdr_calc(all_pvals)
% FDR_CALC Compute False discovery rate using the Storey method
% qvals = FDR_CALC(all_pvals) - uses the Storey method to calculate false discovery rate for the given
%     list of p-values.  Assumes the p-values are calculated intelligently relative to a null, and assigns
%     the expected fraction of null hypotheses to a conservative 1. 

f = ~isnan(all_pvals);
pvals = all_pvals(f)';

if isrow(pvals)
  pvals = pvals';
end

if or(min(pvals) < 0, max(pvals) > 1)
  error('P-values out of range');
end

[~, ix] = sort(pvals, 'ascend');
n = numel(pvals);

myfdr = pvals(ix) * n./(1:numel(pvals))';

% Ghetto
qvals(numel(myfdr)) = 1;
for k = numel(myfdr)-1:-1:1
  qvals(k) = min(myfdr(k), qvals(k+1));
end

qvals(ix) = qvals;

all_qvals = nan(size(all_pvals));
all_qvals(f) = qvals;
end