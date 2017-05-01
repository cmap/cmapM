function modz_ds = level4_to_level5(zsrep_file, col_meta_file, landmark_file, group_var)
% LEVEL4_TO_LEVEL5 Compute Moderated Z-scores (ModZ) from replicate signatures

% zsrep_file = '/Users/narayan/workspace/cmapM/data/TEST_A375_24H_ZSPCINF_n67x22268.gctx';
% col_meta_file = '/Users/narayan/workspace/cmapM/data/TEST_A375_24H_ZSPCINF.map';
% landmark_file = '/Users/narayan/workspace/cmapM/data_processing/resources/L1000_EPSILON.R2.chip';

% z-scores for all replicate signatures
zsrep = parse_gctx(zsrep_file);
% sample annotations
col_meta = parse_tbl(col_meta_file, 'outfmt', 'record');
% landmark annotations
chip = parse_tbl(landmark_file, 'outfmt', 'record');

%% Generate moderated z-score (ModZ) signatures

% Exclude large outlier zscores
zsrep.mat = clip(zsrep.mat, -10, 10);

% Landmark features
pr_id_lm = {chip(strcmp('LM', {chip.pr_type})).pr_id}';
[~, lm_ridx] = intersect(zsrep.rid, pr_id_lm);

% column ids
cid = {col_meta.cid}';

% Group samples
[rep_gp, rep_idx] = getcls({col_meta.(group_var)}');

num_gp = length(rep_gp);
[num_row, num_col] = size(zsrep.mat);
modz_mat = nan(num_row, num_gp);
for ii=1:num_gp
    this_gp = rep_idx == ii;
    this_zs = zsrep.mat(:, this_gp);    
    fprintf(1, '%d/%d %s Computing ModZS %d replicates\n', ii, num_gp, rep_gp{ii}, nnz(this_gp));
    % determine weights based on replicate correlations in landmark space
    [modz_mat(:, ii), wt, cc] = modzs(this_zs, lm_ridx);          
    fprintf(1, 'Replicate correlations\n');
    disp(cc);
    fprintf(1, 'Replicate weights: ');
    disp(wt');
end
% Annotate ModZ matrix
modz_ds = mkgctstruct(modz_mat, 'rid', zsrep.rid, 'cid', rep_gp);
[~, uidx] = unique(rep_idx, 'stable');
modz_meta = keepfield(col_meta(uidx), {'rna_well', 'pert_id',...
                                       'pert_iname', 'pert_type',...
                                       'cell_id','pert_idose',...
                                       'pert_itime'});
modz_ds = annotate_ds(modz_ds, modz_meta);
%modz_ds = annotate_ds(modz_ds, row_meta, 'dim', 'row', 'keyfield', 'pr_id');
end