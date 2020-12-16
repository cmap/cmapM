function ssmd = robust_ssmd(pos_val, neg_val)
% ROBUST_SSMD Strictly standardized median difference
%   SSMD = ROBUST_SSMD(POS, NEG) POS and NEG are numeric vectors
%   representing the signal of positive and negative controls. 
%   SSMD is computed as:
%   SSMD = (MU_neg - MU_pos) / (K*sqrt(SIGMA_neg^2 + SIGMA_pos^2)), where
%   MU_neg and MU_pos are the medians of the negative and positive controls
%   repectively. SIGMA_neg and SIGMA_pos are the corresponding median
%   absolute deviations. K=1.4826

pos_val = pos_val(:);
neg_val = neg_val(:);
np = length(pos_val);
nn = length(neg_val);

assert(np>1 && nn>1,...
    'Expected vector lengths to be >1, got %d and %d instead', np, nn);

k = 1.4826;
mu_pos = nanmedian(pos_val, 1);
mu_neg = nanmedian(neg_val, 1);
sigma_pos = mad(pos_val, 1, 1);
sigma_neg = mad(neg_val, 1, 1);
ssmd = (mu_neg - mu_pos) / (k*sqrt(sigma_neg^2 + sigma_pos^2));

end