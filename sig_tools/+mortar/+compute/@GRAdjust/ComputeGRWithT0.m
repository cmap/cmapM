function [ds_gr, ds_gr_ctl] = ComputeGRWithT0(ds_treat,...
                                              ds_ctl,...
                                              ds_t0,...
                                              min_lfc_ctl,...
                                              max_lfc_ctl,...
                                              p)
% Apply adjustment for cell growth rate to Prism data.
%
%
assert(p>0, 'Parameter p must be >0');
ds_gr = ds_treat;
ds_gr_ctl = mkgctstruct(nan(size(ds_treat.mat, 1), 1),...
                'rid', ds_treat.rid, 'cid', {'GR_CTL'});
ds_gr_ctl = annotate_ds(ds_gr_ctl, gctmeta(ds_gr, 'row'), 'dim', 'row');

[ds_gr.mat, ds_gr_ctl.mat] = grvalue_matrix(pow2(ds_treat.mat),...
                                            pow2(ds_ctl.mat),...
                                            pow2(ds_t0.mat),...
                                            min_lfc_ctl,...
                                            max_lfc_ctl,...
                                            p);
%ds_gr.mat = grvalue_matrix(ds_treat.mat, ds_ctl.mat, ds_t0.mat);
end

function [log2_gr_value, lfc_ctl_vs_t0] = grvalue_matrix(x_treat,...
                                            x_ctl, x_t0, min_lfc_ctl,...
                                            max_lfc_ctl, p)
% Core routine operates on matrices

% 50% Trimmed mean of Control and T0 data matrices (Hafner-2016)
% trim_pct = 50;
% x_ctl_tm = trimmean(x_ctl, trim_pct, 'round', 2);
% x_t0_tm = trimmean(x_t0, trim_pct, 'round', 2);
% lfc_treat = log2(x_treat ./ x_t0_tm);
% lfc_ctl = log2(x_ctl_tm ./ x_t0_tm);

% Median of control and T0 data
x_ctl_agg = nanmedian(x_ctl, 2);
x_t0_agg = nanmedian(x_t0, 2);

lfc_treat_vs_ctl = (log2(x_treat) - log2(x_ctl_agg));
lfc_ctl_vs_t0 = log2(x_ctl_agg) - log2(x_t0_agg);
lfc_ctl_vs_t0_clipped = clip(lfc_ctl_vs_t0, min_lfc_ctl, max_lfc_ctl);
log2_gr_value = lfc_treat_vs_ctl ./ (lfc_ctl_vs_t0_clipped).^(1/p);

end
