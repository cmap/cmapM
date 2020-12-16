function zs = zscore_by_cohort(ds_file, meta_data_file, cohort_field)
% profile_file: GCT(x) file of profiles to zscore
% clusterdef_file: TSV with sample_id, tcga_id, cohort, cluster


%% Load datasets
ds = parse_gctx(ds_file);
if ~isempty(meta_data_file)
    ds = annotate_ds(ds, meta_data_file);    
end
meta_data = gctmeta(ds);

%% define groups and zscore
[gpv, gpn, gpi, ~, gpsz] = get_groupvar(meta_data, fieldnames(meta_data),...
                    cohort_field);                
ngp = length(gpn);

zs = ds;
for ii=1:ngp
    cidx = find(gpi == ii);
    zs.mat(:, cidx) = robust_zscore(zs.mat(:, cidx), 2,...
                        'var_adjustment', 'fixed', ...
                        'min_mad', 0.1);
    dbg(1, 'Cohort %d/%d %s (n=%d)', ii, ngp, gpn{ii}, gpsz(ii));    
end                
zs = ds_add_meta(zs, 'column', 'zs_cohort', gpv);

end
