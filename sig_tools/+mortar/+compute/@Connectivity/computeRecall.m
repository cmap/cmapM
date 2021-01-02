function rpt = computeRecall(score, col_field, row_field, recall_metric, fix_ties)
% rpt = computeRecall(score, col_field, row_field, recall_metric, fix_ties)

assert(ischar(recall_metric), 'Expected recall_metric to be a string');
score = parse_gctx(score);
% Compute percentile ranks along both dimensions
col_rnk = score2rank(score, 'direc', 'descend', 'as_percentile', true, 'fixties', fix_ties);
row_rnk = score2rank(score, 'direc', 'descend', 'dim', 'row', 'as_percentile', true, 'fixties', fix_ties);

%% self connectivity table
col_name = paste(ds_get_meta(score, 'column', col_field), ':');
row_name = paste(ds_get_meta(score, 'row', row_field), ':');
%col_name = get_groupvar(score.cdesc, score.chd, col_field);
%[row_name, row_gpn, row_gpi] = get_groupvar(score.rdesc, score.rhd, row_field);

%[col_gpn, col_gpi] = getcls(col_name);
[row_gpn, row_gpi] = getcls(row_name);

%[cmn_gpn, cmn_idx] = intersect(col_gpn, row_gpn, 'stable');

row_lut = mortar.containers.Dict(row_gpn);

%ncol = length(col_name);
%nrow = length(row_name);

row_idx = row_lut(col_name);
%col_idx = (1:ncol)';

mask = bsxfun(@eq, row_gpi, row_idx');
num_match = nnz(mask);
if ~num_match
    col_field_csv = print_dlm_line(col_field,'dlm', ',');
    row_field_csv = print_dlm_line(row_field,'dlm', ',');
    error('Could not match Columns to Rows based on Col:%s Row:%s, cannot proceed', col_field_csv, row_field_csv);
end
%isok = ~isnan(row_idx);
%mask = zeros(nrow, ncol);
%idx = sub2ind(size(mask),row_idx(isok), col_idx(isok));
%mask(idx) = 1;
score = ds_add_meta(score, 'column', 'recall_group', col_name);
rpt_ncs = ds_get_hits(score, mask);
rpt_ncs = mvfield(rpt_ncs, {'hit_value','col_recall_group'}, {'recall_score', 'recall_group'});
rpt_col_rnk = ds_get_hits(col_rnk, mask);
rpt_col_rnk = mvfield(rpt_col_rnk, 'hit_value', 'recall_col_rank');
rpt_row_rnk = ds_get_hits(row_rnk, mask);
rpt_row_rnk = mvfield(rpt_row_rnk, 'hit_value', 'recall_row_rank');

rpt = join_table(rpt_ncs, rpt_col_rnk, 'id', 'id', 'recall_col_rank');
rpt = join_table(rpt, rpt_row_rnk, 'id', 'id', 'recall_row_rank');
rpt = setarrayfield(rpt, [], 'max_col_rank', size(score.mat, 1));
rpt = setarrayfield(rpt, [], 'max_row_rank', size(score.mat, 2));

% Add symmetricized rank (mean of row and column ranks)
recall_col_rank = [rpt.recall_col_rank]';
recall_row_rank = [rpt.recall_row_rank]';
recall_rank = 0.5*(recall_col_rank + recall_row_rank);
recall_score = [rpt.recall_score]';
% ranks are in percentiles
max_rank = 100;
% Composite score : geometric mean of clipped score and inverted ranks
recall_composite = sqrt(clip(recall_score, 0.001, inf).* (max_rank - recall_rank)/max_rank);
rpt = setarrayfield(rpt, [],...
            {'recall_metric', 'recall_rank', 'recall_composite', 'max_rank'},...
            recall_metric, recall_rank, recall_composite, max_rank);

end