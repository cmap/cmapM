% function pkstats = adhocTest
% 
inpath = '/cmap/obelix/lxb';
plate = 'DEV_PRISM_PREP005_P7P8_X1';
% well = 'C01';
% lxb = parse_lxb(fullfile(inpath, plate, sprintf('%s_%s.lxb', plate, well)));
% pkstats = mortar.prism.dpeak.dpeakMultiAnalyte(lxb.RP1, lxb.RID, opt_args{:});
% end
lxb_path = fullfile(inpath, plate);
% run dpeak
[pkstats, fn] = mortar.prism.dpeak.dpeakFolder(lxb_path);
% assign peaks
ds = mortar.prism.dpeak.assignPeaks(pkstats);
%%
analyte_id=gen_labels([pkstats(:,1).analyte],'prefix', 'Analyte ','zeropad',false);
wn = get_wellinfo(fn);
ds_high=mkgctstruct(ds(1).mat,'rid', analyte_id,'cid',wn);
ds_low=mkgctstruct(ds(2).mat,'rid', analyte_id,'cid',wn);
%% combine and add annotations
feature_map_file = '/Users/narayan/workspace/prism_duo/feature_map.txt';
feature_map = parse_record(feature_map_file);
is_high = strcmp({feature_map.det_pool}','high');
feature_high = feature_map(is_high);
feature_low = feature_map(~is_high);
ds_high_filt = ds_slice(ds_high, 'rid', {feature_high.analyte_id}');
ds_high_filt = annotate_ds(ds_high_filt, feature_high, 'keyfield', 'analyte_id', 'dim', 'row');
rid_high = ds_get_meta(ds_high_filt,'row','cell_id');
ds_high_filt.rid = rid_high;
ds_high_filt = ds_delete_meta(ds_high_filt, 'row', 'cell_id');

ds_low_filt = ds_slice(ds_low, 'rid', {feature_low.analyte_id}');
ds_low_filt = annotate_ds(ds_low_filt, feature_low, 'keyfield', 'analyte_id', 'dim', 'row');
rid_low = ds_get_meta(ds_low_filt,'row','cell_id');
ds_low_filt.rid = rid_low;
ds_low_filt = ds_delete_meta(ds_low_filt, 'row', 'cell_id');

ds_combo = merge_two(ds_high_filt, ds_low_filt);

%% percent of analytes with 2 viable peaks
support_duo = {pkstats(101:200,:).pksupport};
support_pct_duo = {pkstats(101:200,:).pksupport_pct};
% 2 peaks 
has_two = reshape(cellfun(@(x) ifelse(numel(x)>1, true, false), support_duo), 100, 384);
peak2_support = reshape(cellfun(@(x) x(min(2, numel(x))), support_duo), 100, 384);
peak2_supporplt(~has_two) = 0;
peak2_support_pct = reshape(cellfun(@(x) x(min(2, numel(x))), support_pct_duo), 100, 384);
peak2_support_pct(~has_two) = 0;
has_two_viable = has_two & peak2_support>=10 & peak2_support_pct>=10;
pct_viable_sample = 100*sum(has_two_viable, 1) / size(has_two_viable, 1);
pct_viable_analyte = 100*sum(has_two_viable, 2) / size(has_two_viable, 2);
%% self connectivity
ds_path='/cmap/data/rnwork/prism_duo/kspeak/';
x1=parse_gctx(fullfile(ds_path, 'DEV_PRISM_PREP005_P7P8_X1_DPEAK_n384x578.gct'));
x2=parse_gctx(fullfile(ds_path, 'DEV_PRISM_PREP005_P7P8_X2_DPEAK_n384x578.gct'));
log2x1 = x1;
log2x1.mat = log2(log2x1.mat);

log2x2 = x2;
log2x2.mat = log2(log2x2.mat);
wtcs = mortar.compute.Connectivity.compareMatrices(log2x1,log2x2,...
                                    'dim', 'column','set_size',50);
rnk = wtcs;
rnk.mat = rankorder(rnk.mat, 'direc', 'ascend', 'as_fraction', true);

%% wtcs vs rank
figure
scatter(diag(wtcs.mat), diag(rnk.mat));
xlim([0,1]);
ylim([0,1]);
xlabel('wtcs50');
ylabel('self rank');
title('Self Connectivity')
namefig('xy_replicate_wtcs_vs_rank')
%% scatter density plots
figure
plot_scatterdensity(diag(wtcs.mat),diag(rnk.mat),100,5)
xlabel('wtcs50');
ylabel('self rank');
namefig('sd_replicate_wtcs_vs_rank');

figure
plot_scatterdensity(tri2vec(wtcs.mat),tri2vec(rnk.mat),100,5)
xlabel('wtcs50');
ylabel('self rank');
namefig('sd_nonreplicate_wtcs_vs_rank');
%%
figure
%plot_norm_hist(tri2vec(wtcs.mat),30,'style','step');
ksdensity(tri2vec(wtcs.mat));
hold on
% plot_norm_hist(diag(wtcs.mat),30,'style','step');
ksdensity(diag(wtcs.mat));
legend('non-replicate', 'replicate')
xlim([0 1])
title('Self Connectivity WtCS 50')
namefig('ksd_self_conn_wtcs')
%%
figure
%plot_norm_hist(tri2vec(rnk.mat),30,'style','step');
ksdensity(tri2vec(rnk.mat));
hold on
%plot_norm_hist(diag(rnk.mat),30,'style','step');
ksdensity(diag(rnk.mat));
legend('non-replicate', 'replicate')
xlim([0 1])
title('Self Connectivity Rank')
namefig('ksd_self_conn_rank')
%%
detect_params = mortar.prism.dpeak.detect_params;
opt_args = args2cell(detect_params);
well = 'D02';
lxb = parse_lxb(fullfile(inpath, plate, sprintf('%s_%s.lxb', plate, well)));
idx=101:200;
%idx=176;
num_peak=zeros(numel(idx),1);
for ii=1:numel(idx);
    analyte_num=idx(ii);
    pkstats=mortar.prism.dpeak.dpeakSingleAnalyte(lxb.RP1(lxb.RID==analyte_num),...
        opt_args{:}, 'showfig',false);
    num_peak(ii)=sum([pkstats.pksupport_pct]>=10 & [pkstats.pksupport]>=10);
    pk_support_pct = print_dlm_line([pkstats.pksupport_pct], 'dlm', ',', 'precision', 1);
    pk_support = print_dlm_line([pkstats.pksupport], 'dlm', ',', 'precision', 1);
    dbg(1, 'Analyte %d, num peaks: %d support_pct: %s support: %s',...
        analyte_num, num_peak(ii), pk_support_pct, pk_support); 
    if num_peak(ii)>1      
        pkstats = mortar.prism.dpeak.dpeakSingleAnalyte(lxb.RP1(lxb.RID==analyte_num),...
            opt_args{:}, 'showfig',true);
    end
end

% end