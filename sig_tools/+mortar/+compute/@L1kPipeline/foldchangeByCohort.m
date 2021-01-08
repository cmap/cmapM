function [fc, status] = foldchangeByCohort(ds_file, meta_data_file, cohort_field, ctl_field, ctl_id)
% foldchangeByCohort Compute fold change relative to a specified control
% sample
% [fc, status] = foldchangeByCohort(ds_file, meta_data_file, cohort_field, bkg_field, bkg_id)

% profile_file: GCT(x) file of profiles to zscore
% clusterdef_file: TSV with sample_id, tcga_id, cohort, cluster

% profile_file = '/cmap/projects/sig_tcga/ds/TCGA_RNASEQ.RSEM_PROFILE.L1KBING_n2493x7438.gctx';
% clusterdef_file = ['/cmap/projects/sig_tcga/subtype_definition/' ...
%                'cohort_clusters.txt'];

%% Load datasets
ds = parse_gctx(ds_file);
if ~isempty(meta_data_file)
    ds = annotate_ds(ds, meta_data_file);    
end
meta_data = gctmeta(ds);
ctl_group = ds_get_meta(ds, 'column', ctl_field);
is_ctl = strcmp(ctl_group, ctl_id);

%% define groups and compute fold change
[gpv, gpn, gpi, ~, gpsz] = get_groupvar(meta_data, fieldnames(meta_data),...
                    cohort_field);                
ngp = length(gpn);

fc = ds;
status = struct('cohort', gpn,...
                'cohort_size', num2cell(gpsz),...
                'was_processed', true,...
                'comment', 'None');
for ii=1:ngp
    dbg(1, 'Cohort %d/%d %s (n=%d)', ii, ngp, gpn{ii}, gpsz(ii));    
    cidx = gpi == ii;
    this_ctl = cidx & is_ctl;
    num_ctl = nnz(this_ctl);
    if num_ctl
        ctl_vec = nanmean(fc.mat(:, this_ctl), 2);
        fc.mat(:, cidx) = bsxfun(@minus, fc.mat(:, cidx), ctl_vec);
    else
        warning('%d/%d %s (n=%d) No control samples found, skipping', ii, ngp, gpn{ii}, gpsz(ii));    
        fc.mat(:, cidx) = nan;
        status(ii).was_processed = false;
        status(ii).comment = 'NO_CONTROL_SAMPLE';
    end    
end                
fc = ds_add_meta(fc, 'column', 'cohort_id', gpv);

end
