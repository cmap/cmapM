function [ds_gr, ds_num_double] = ComputeGRWithTd(ds_treat, ds_ctl, tbl_td, t, min_dbl, max_dbl)
% Apply adjustment for cell growth rate to Prism data using pre-computed
% cell doubling times
%
%
cell_field = 'cell_iname';
td_field = 't_doubling';
ncell = length(ds_treat.rid);
ds_gr = ds_treat;
ds_num_double = mkgctstruct(nan(size(ds_treat.mat, 1), 1), 'rid', ds_treat.rid, 'cid', {'GR_CTL'});
ds_num_double = annotate_ds(ds_num_double, gctmeta(ds_gr, 'row'), 'dim', 'row');

cell_key_tbl = {tbl_td.(cell_field)}';
cell_key_ds = ds_get_meta(ds_treat, 'row', cell_field);
[cmn, ~, ib] = intersect(cell_key_ds, cell_key_tbl, 'stable');
assert(isequal(length(cmn), ncell), 'Td not found for %d cell lines', ncell-length(cmn));
td = [tbl_td(ib).(td_field)]';

[ds_gr.mat, ds_num_double.mat] = grtd_matrix(pow2(ds_treat.mat), pow2(ds_ctl.mat), td, t, min_dbl, max_dbl);

end

function [log2_gr_value, num_doubling] = grtd_matrix(x_treat, x_ctl, td, t, min_dbl, max_dbl)
% Core routine operates on matrices

% Median of control and T0 data
x_ctl_agg = nanmedian(x_ctl, 2);

lfc_treat_vs_ctl = (log2(x_treat) - log2(x_ctl_agg));
num_doubling = t./td;
num_doubling_clipped = clip(num_doubling, min_dbl, max_dbl);

log2_gr_value = lfc_treat_vs_ctl ./ num_doubling_clipped;

end
