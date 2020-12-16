function [row_meta, h] = plotGainVsSelectivity(ds, sel_rpt)

ds=parse_gctx(ds, 'annot_only', true);
pert_type = ds_get_meta(ds, 'row', 'pert_type');
is_xpr = strcmp(pert_type, 'trt_xpr');
ds_xpr = ds_slice(ds, 'ridx', is_xpr);
ds_filt = mortar.compute.DiffConn.filterBestConnections(ds_xpr, 85, 2);
% stratified gain
%gain_strat = mortar.compute.DiffConn.computeGainStratified(ds_get_meta(ds_filt, 'row', 'pos_q'), ds_get_meta(ds_filt, 'row', 'neg_q'), 85);
%ds_filt = ds_add_meta(ds_filt, 'row', 'gain_strat', num2cell(gain_strat));
% diffconn gain
gain = mortar.compute.DiffConn.computeGain(ds_get_meta(ds_filt, 'row', 'pos_q'),...
                    ds_get_meta(ds_filt, 'row', 'neg_q'));
ds_filt = ds_add_meta(ds_filt, 'row', 'gain', num2cell(gain));
row_meta = gctmeta(ds_filt, 'row');
row_meta = join_table(row_meta, sel_rpt, 'rid', 'rid');
%%
query_names = ds_get_meta(ds_filt, 'column', 'pert_iname');
query_name = query_names{1};
row_meta = setarrayfield(row_meta, [], 'query_name', query_name);

num_features = length(row_meta);
num_perts = length(unique({row_meta.pert_id}'));

h = figure;
sel_binned = str2double({row_meta.selectivity_percentile}');
%scatter([row_meta.selectivity_ps85]', [row_meta.gain]', 7, abs([row_meta.pos_q]'))
% absolute max of positive and negative class scores
cnx_score = absmax([[row_meta.pos_q]', [row_meta.neg_q]'], 2);
%cnx_score = [row_meta.pos_q]';
is_sig_score = abs(cnx_score)>=85;
num_signif = nnz(is_sig_score);
scatter(sel_binned(~is_sig_score) + randn(size(sel_binned(~is_sig_score))), [row_meta(~is_sig_score).gain]', 6, cnx_score(~is_sig_score), 'filled')
hold on
scatter(sel_binned(is_sig_score) + randn(size(sel_binned(is_sig_score))), [row_meta(is_sig_score).gain]', 9, cnx_score(is_sig_score), 'filled')
colorbar
caxis([-100, 100]);
colormap(taumap_redblue85)
xlabel('Selectivity Percentiles')
ylabel('DiffConn Score')
title(sprintf('%s, %d features %d perts %d signif', query_name, num_features, num_perts, num_signif))
namefig(sprintf('%s_sel_vs_gain', query_name));
end
