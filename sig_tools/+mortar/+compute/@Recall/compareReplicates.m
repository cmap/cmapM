function [pair_recall_rpt, set_recall_rpt, rep_recall_rpt,...
          rep_stats_rpt, pw_matrices, ds_pairs] = compareReplicates(varargin)
% compareReplicates 

[args, help_flag] = getArgs(varargin{:});
if ~help_flag    
        % Read and validate datasets
        dbg(1, '# Loading Datasets');
        [ds_cell, ds_path] = parse_gct_list(args.ds_list,...
                                'row_filter', args.row_filter,...
                                'column_filter', args.column_filter);
        [ds_cell, match_field] = validateInputs(args, ds_cell);
        num_ds = length(ds_cell);
        
        % Perform pairwise recall
        dbg(1, '# Running pairwise comparisons of %d datasets by %s using %s',...
            num_ds, args.dim, args.metric);
        [pw_recall_rpt, pw_matrices, ds_pairs] = pairwiseRecall(ds_cell, args);
        
        % Merge reports
        pair_recall_rpt = mergeRecallReport(pw_recall_rpt, match_field, args);    
        
        % per-replicate report
        [rep_recall_rpt, rep_stats_rpt] = mortar.compute.Recall.getReplicateReport(pair_recall_rpt, args.outlier_alpha);
        
        % Summarize pairwise recall to recall sets
        set_recall_rpt = getSetReport(pair_recall_rpt, match_field, args);
else
    % help selected do nothing
end

end

function [ds_cell, match_field] = validateInputs(args, ds_cell)
num_ds = length(ds_cell);
assert(num_ds>1, 'Need at least 2 datasets to compare');
dim_str = get_dim2d(args.dim);
for ii=1:num_ds
    % check if match field(s) exist
    sample_field = ds_get_meta(ds_cell{ii}, 'column', args.sample_field);    
    feature_field = ds_get_meta(ds_cell{ii}, 'row', args.feature_field);        
    % transpose matrices if dim is row
    if isequal(dim_str, 'row')
        ds_cell{ii} = transpose_gct(ds_cell{ii});
    end
end
if isequal(dim_str, 'column')
    match_field = args.sample_field;
else
    match_field = args.feature_field;
end

end

function [recall_rpt, pw_matrices, ds_pairs] = pairwiseRecall(ds_cell, args)
num_ds = length(ds_cell);
% all combinations of pairs
pair_list = sorton(combnk(1:num_ds, 2),[1,2]);
num_pair = size(pair_list, 1);
recall_rpt = cell(num_pair, 1);
pw_matrices = cell(num_pair, 1);
ds_pairs = cell(num_pair, 2);

for ii=1:num_pair
    ia = pair_list(ii, 1);
    ib = pair_list(ii, 2);
    path_a = ds_cell{ia}.src;
    path_b = ds_cell{ib}.src;
    name_a = basename(path_a);
    name_b = basename(path_b);
    ds_comparison = sprintf('%d_vs_%d', ia, ib);
    ds1_name = name_a{1};
    ds2_name = name_b{1};  
    dbg(1, '%d/%d %s', ii, num_pair, ds_comparison);
    if isequal(path_a, path_b)
        dbg(1, 'Comparing the same dataset, ignoring self-similarities (diagonal elements)')
        ignore_diagonal = true;
    else
        ignore_diagonal = false;
    end
    [recall_rpt{ii}, ds_sim, ds1, ds2] = recallTwo(ds_cell{ia}, ds_cell{ib}, args, ignore_diagonal);
    % Save similarity matrices if requested
    if args.save_pw_matrix
        ds_sim.src = sprintf('%s_similarity.gctx', ds_comparison);
        pw_matrices{ii} = ds_sim;
        ds1.src = sprintf('%s_ds1.gctx', ds_comparison);
        ds2.src = sprintf('%s_ds2.gctx', ds_comparison);
        ds_pairs{ii, 1} = ds1;
        ds_pairs{ii, 2} = ds2;
    end
    
    recall_rpt{ii} = setarrayfield(recall_rpt{ii}, [],...
        {'ds_comparison', 'ds1_name', 'ds2_name'},...
        ds_comparison, ds1_name, ds2_name);
end
end

function [recall_rpt, ds_sim, ds1, ds2] = recallTwo(ds1, ds2, args, ignore_diagonal)

% slice to shared features
dim_str = get_dim2d(args.dim);
switch dim_str
    case 'column'
        ds1_features = get_groupvar(gctmeta(ds1, 'row'), [], args.feature_field);
        ds2_features = get_groupvar(gctmeta(ds2, 'row'), [], args.feature_field);        
        [cmn_features, ia, ib] = intersect(ds1_features, ds2_features, 'stable');
        dbg(1, 'Comparing matrices by %d common features found by grouping on %s',...
            numel(cmn_features), print_dlm_line(args.feature_field, 'dlm', ','));
        ds1 = ds_slice(ds1, 'rid', ds1.rid(ia));
        ds2 = ds_slice(ds2, 'rid', ds2.rid(ib)); 
        ds1.rid = cmn_features;
        ds2.rid = cmn_features;
        match_field = args.sample_field;
    case 'row'       
        % was transposed previously
        ds1_features = get_groupvar(gctmeta(ds1, 'row'), [], args.sample_field);
        ds2_features = get_groupvar(gctmeta(ds2, 'row'), [], args.sample_field);
        [cmn_features, ia, ib] = intersect(ds1_features, ds2_features, 'stable');
        dbg(1, 'Comparing matrices by %d common features found by grouping on %s',...
            numel(cmn_features), print_dlm_line(args.sample_field, 'dlm', ','));
        ds1 = ds_slice(ds1, 'rid', ds1.rid(ia));
        ds2 = ds_slice(ds2, 'rid', ds2.rid(ib));
        ds1.rid = cmn_features;
        ds2.rid = cmn_features;
        match_field = args.feature_field;
end

switch args.metric
    case {'spearman', 'pearson'}
        ds_sim = ds_corr(ds1, ds2, 'type', args.metric);
        recall_metric = args.metric;
    case {'cosine'}
        ds_sim = ds_cosine(ds1, ds2);
        recall_metric = args.metric;       
    case {'wtcs', 'cs'}
        is_weighted = strcmp(args.metric, 'wtcs');
        ds_sim = mortar.compute.Connectivity.compareMatrices(ds1, ds2,...
            '--dim', 'column', '--set_size', args.set_size,...
            '--is_weighted', is_weighted, '--es_tail', args.es_tail);
        recall_metric = sprintf('%s.%d.%s', args.metric, args.set_size, args.es_tail);
end

if ignore_diagonal
    % mask self-connections before computing ranks
    ds_sim.mat = set_diagonal(ds_sim.mat, nan);    
end
recall_rpt = mortar.compute.Connectivity.computeRecall(ds_sim, match_field, match_field, recall_metric, args.fix_ties);

if ignore_diagonal
    % delete self connections
    is_same_id = strcmp({recall_rpt.row_rid}, {recall_rpt.col_cid});
    recall_rpt(is_same_id) = [];
end

% Recall grouping variable
recall_group = {recall_rpt.recall_group}';
if ~isempty(args.recall_group_prefix)
    recall_group = strcat(args.recall_group_prefix, ':', recall_group);
end
recall_rpt = setarrayfield(recall_rpt, [],...
                {'recall_group', 'recall_metric'},...
                recall_group, recall_metric);
end

function meta_fields = getDefaultMetaFields(dim)
dim_str = get_dim2d(dim);
switch dim_str
    case 'column'
        meta_fields = {'pert_id'; 'pert_iname'; 'pert_type';...
            'cell_id'; 'pert_idose'; 'pert_itime';...
            'pert_mfc_id'; 'pert_mfc_desc'};
    case 'row'
        meta_fields = {'pr_gene_id'; 'pr_gene_symbol';...
                'pr_analyte_id'; 'pr_bset_id'};
end
end

function recall_rpt = mergeRecallReport(pw_recall_rpt, match_field, args)
num_rpt = length(pw_recall_rpt);

meta_fields = getDefaultMetaFields(args.dim);
head_fields = {'recall_group'; 'id'; 'col_cid'; 'row_rid';...
               'recall_metric'; 'ds_comparison'; 'ds1_name'; 'ds2_name'};
metric_fields = {'recall_score'; 'recall_rank'; 'recall_composite'; 'max_rank';...
                'recall_col_rank';...
                'recall_row_rank'; 'max_col_rank';...
                'max_row_rank'};
keep_fields = union(match_field, meta_fields, 'stable');
row_fn = strcat('row_', keep_fields);
col_fn = strcat('col_', keep_fields);
all_fields = [head_fields; col_fn; metric_fields; row_fn];

recall_rpt = formatRecallReport(pw_recall_rpt{1}, all_fields);
for ii=2:num_rpt
    this_rpt = formatRecallReport(pw_recall_rpt{ii}, all_fields);
    recall_rpt = [recall_rpt; this_rpt];
end
if isfield(recall_rpt, 'recall_group')
    [~, rec_ord] = sort({recall_rpt.recall_group}');
    recall_rpt = recall_rpt(rec_ord);
end

end

% function [rep_recall_rpt, rep_stats_rpt] = getReplicateReport(pair_recall_rpt)
% % Summary report per unique replicate(X1, X2 etc)
% 
% recall_metric = pair_recall_rpt(1).recall_metric;
% recall_score = [[pair_recall_rpt.recall_score]'; [pair_recall_rpt.recall_score]'];
% recall_rank = [[pair_recall_rpt.recall_rank]';[pair_recall_rpt.recall_rank]'];
% recall_composite = [[pair_recall_rpt.recall_composite]'; [pair_recall_rpt.recall_composite]'];
% replicate_id = [{pair_recall_rpt.ds1_name}'; {pair_recall_rpt.ds2_name}'];
% [cn, nl] = getcls(replicate_id);
% uniq_replicate_name = get_tokens(cn, 4, 'dlm', '_');
% replicate_name = uniq_replicate_name(nl);
% max_rank = max([pair_recall_rpt.max_rank]);
% 
% rep_recall_rpt = struct('replicate_id', replicate_id,...
%        'replicate_name', replicate_name,...
%        'recall_metric', recall_metric,...
%        'recall_score', num2cell(recall_score),...
%        'recall_rank', num2cell(recall_rank),...
%        'recall_composite', num2cell(recall_composite),...
%        'max_rank', max_rank);
% 
% rep_stats_rpt = mortar.compute.Recall.detectOutlierReplicates(recall_rank, replicate_id);
% rep_stats_rpt = setarrayfield(rep_stats_rpt, [], {'replicate_name'}, replicate_name);
% rep_stats_rpt = orderfields(rep_stats_rpt, orderas(fieldnames(rep_stats_rpt),...
%                     {'replicate_id', 'replicate_name'}));
% % % test for statistical diff between ranks
% % alpha = 0.01;
% % rep_stats_rpt = struct('replicate_id', cn,...
% %                    'replicate_name', uniq_replicate_name,...
% %                    'npoints', nan,...
% %                    'median', nan,...
% %                    'iqr', nan,...
% %                    'ranksum_nlogp', nan,...
% %                    'ranksum_h', nan,...
% %                    'ranksum_stat', nan,...
% %                    'ranksum_zs', nan,...
% %                    'kstest_nlogp', nan,...
% %                    'kstest_h', nan,...
% %                    'kstest_stat', nan);
% %                
% % nrep = length(cn);
% % for ii=1:nrep
% %     this_rep = nl == ii;
% %     not_this_rep = ~this_rep;
% %     x = recall_rank(this_rep);
% %     y = recall_rank(not_this_rep);
% %     %y = recall_rank;
% %     this_npoints = length(x);
% %     this_median = nanmedian(x);
% %     this_iqr = naniqr(x);
% %     % one-tailed Wilcoxon rank-sum test if median(x) > median(y)
% %     [rs_p, rs_h, rs_stats] = ranksum(x, y, 'tail', 'right',...
% %                                     'alpha', alpha);
% % 
% %     % one-tailed KS test if CDF(x) < CDF(y)
% %     [ks_h, ks_p, ks_stats] = kstest2(x, y, 'tail', 'smaller',...
% %                                     'alpha', alpha);
% %     rep_stats_rpt = setarrayfield(rep_stats_rpt, ii,...
% %                   {'npoints',...
% %                   'median',...
% %                   'iqr', ...
% %                   'ranksum_nlogp',...
% %                   'ranksum_h',...
% %                    'ranksum_stat',...
% %                    'ranksum_zs',...
% %                    'kstest_nlogp',...
% %                    'kstest_h',...
% %                    'kstest_stat'},...
% %                    this_npoints,...
% %                    this_median,...
% %                    this_iqr,...
% %                    -log10(rs_p), rs_h, rs_stats.ranksum, rs_stats.zval,...
% %                    -log10(ks_p), ks_h, ks_stats);
% % end                   
% 
% end

function set_recall_rpt = getSetReport(pair_recall_rpt, match_field, args)
% Summarize pairwise recall for each replicate set

if isfield(pair_recall_rpt, 'recall_group')
    [gpv, gpn, gpi, ~, gpsz] = get_groupvar(pair_recall_rpt, [], 'recall_group');
    head_fields = {'recall_group'; 'recall_metric'};
    metric_fields = {'recall_score'; 'recall_rank'; 'recall_composite'; 'max_rank';...
                'recall_col_rank';...
                'recall_row_rank'; 'max_col_rank';...
                'max_row_rank'};                       
    meta_fields = getDefaultMetaFields(args.dim);
    keep_fields = union(match_field, meta_fields, 'stable');
    row_fn = strcat('row_', keep_fields);
    col_fn = strcat('col_', keep_fields);
    all_fields = [head_fields; col_fn; row_fn];        
    [~, uidx] = unique(gpi, 'stable');
    set_recall_rpt = keepfield(pair_recall_rpt(uidx), all_fields);
    set_recall_rpt = setarrayfield(set_recall_rpt, [], 'num_replicate', gpsz);
    for ii=1:length(metric_fields)    
        this_metric = [pair_recall_rpt.(metric_fields{ii})]';
        med_val = grpstats(this_metric, gpv,...
                                      {@nanmedian});
        med_field = strcat('median_', metric_fields{ii});
        set_recall_rpt = setarrayfield(set_recall_rpt, [],...
                  {med_field},...
                  med_val);
    end    
else
    error('recall_group field not found');
end

end


function recall_rpt = formatRecallReport(recall_rpt, keep_fields)
fn = fieldnames(recall_rpt);
missing_fn = setdiff(keep_fields, fn);
if ~isempty(missing_fn)
    missing_val = cell(length(missing_fn), 1);
    missing_val(:) = {'-666'};
    recall_rpt = setarrayfield(recall_rpt, [], missing_fn, missing_val{:});
    recall_rpt = keepfield(recall_rpt, keep_fields);
    %recall_rpt = orderfields(recall_rpt, orderas(fieldnames(recall_rpt), keep_fields));
else
    recall_rpt = keepfield(recall_rpt, keep_fields);
end


end

function [args, help_flag] = getArgs(varargin)
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', '', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    % sanity checks
    assert(~isempty(args.ds_list), 'ds_list cannot be empty');    
    assert(~isempty(args.sample_field), 'sample_field cannot be empty');
    assert(~isempty(args.feature_field), 'feature_field cannot be empty');
    args.sample_field = tokenize(args.sample_field, ',', true);
    args.feature_field = tokenize(args.feature_field, ',', true);
end

end