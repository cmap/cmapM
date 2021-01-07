function runAnalysis_(obj, varargin)
args = obj.getArgs;
out_path = obj.getWkdir;
obj.res_ = main(args, out_path);
end

function res = main(args, out_path)
% Main function

res = struct('args', args, 'recall_stats', '');

[ds_table, ds_skipped_list] = getDSTable(args.ds_list);
if ~isempty(ds_skipped_list)
    mkgrp(fullfile(out_path, 'ds_skipped.grp'), ds_skipped_list);
end
[~, ds_group, ds_group_idx] = get_groupvar(ds_table, [], 'group_id');
num_ds_group = length(ds_group);
dbg(1, '# Running recall analysis on %d dataset groups', num_ds_group)

dim_str = get_dim2d(args.dim);
if isequal(dim_str, 'column') &&...
        isequal(length(args.sample_field), 1) &&...
        all(rematch(args.sample_field, 'well'))
    platemap_field = strcat('col_', args.sample_field{1});
else
    platemap_field = '';
end

show_fig = args.show_fig>0;
res.recall_stats = struct('recall_group', ds_group, 'url', '');

for ii = 1:num_ds_group
    dbg(1, '# %d/%d %s', ii, num_ds_group, ds_group{ii});
    this_group = ds_group_idx == ii;
    this_ds_list = {ds_table(this_group).file_path}';
    [pair_recall_rpt, set_recall_rpt, rep_recall_rpt,...
        rep_stats_rpt, pw_matrices, ds_pairs] = ...
        mortar.compute.Recall.compareReplicates(...
        '--ds_list', this_ds_list,...
        '--sample_field', args.sample_field,...
        '--feature_field', args.feature_field,...
        '--row_filter', args.row_filter,...
        '--column_filter', args.column_filter,...
        '--metric', args.metric,...
        '--dim', args.dim,...
        '--set_size', args.set_size,...
        '--es_tail', args.es_tail,...
        '--recall_group_prefix', ds_group{ii},...
        '--save_pw_matrix', args.save_pw_matrix,...
        '--outlier_alpha', args.outlier_alpha);
    
    this_out_path = fullfile(out_path, ds_group{ii});
    if length(pair_recall_rpt)>0
        [recall_summary, index_path] = saveReport(...
            pair_recall_rpt, set_recall_rpt, rep_stats_rpt,...
            rep_recall_rpt, platemap_field, this_out_path,...
            show_fig, ds_group{ii});
        if args.save_pw_matrix
            dbg(1, '# Saving Pairwise matrices');
            saveMatrices(this_out_path, pw_matrices, ds_pairs);
        end
        res.recall_stats = join_table(res.recall_stats, recall_summary,...
            'recall_group', 'recall_group');
        res.recall_stats(ii).url = index_path;
    end
end

end

function saveMatrices(out_path, pw_matrices, ds_pairs)
npairs = length(pw_matrices);
for ii=1:npairs
    this_file = fullfile(out_path, pw_matrices{ii}.src);
    mkgctx(this_file, pw_matrices{ii});
    ds1 = ds_pairs{ii, 1};
    ds2 = ds_pairs{ii, 2};
    ds1_file = fullfile(out_path, ds1.src);
    ds2_file = fullfile(out_path, ds2.src);
    
    mkgctx(this_file, pw_matrices{ii});
    mkgctx(ds1_file, ds1);
    mkgctx(ds2_file, ds2);
end
end

function [recall_summary, index_page] = saveReport(...
    pair_recall_rpt, set_recall_rpt, rep_stats_rpt,...
    rep_recall_rpt, platemap_field, out_path,...
    show_fig, recall_group)

mkdirnotexist(out_path);
if length(pair_recall_rpt)>0
    jmktbl(fullfile(out_path, 'recall_report_pairs.txt'), pair_recall_rpt);
    jmktbl(fullfile(out_path, 'recall_report_sets.txt'), set_recall_rpt);
    jmktbl(fullfile(out_path, 'recall_report_datasets.txt'), rep_stats_rpt);
    
    % Generate plots
    h0 = findobj('type', 'figure');
    
    [h1, recall_summary] = mortar.compute.Recall.plotPerSet(...
        set_recall_rpt, platemap_field, 'showfig', show_fig, 'ylabelrt', recall_group);
    
    [h2, pair_recall_summary] = mortar.compute.Recall.plotPerPair(...
        pair_recall_rpt, 'showfig', show_fig, 'ylabelrt', recall_group);
    
    %% add info for index
    % check if Wilcoxon ranksum test was significant
    is_bad_rep = [rep_stats_rpt.ranksum_h]'>0;
    num_rep = length(rep_stats_rpt);
    outlier_name = print_dlm_line({rep_stats_rpt(is_bad_rep).replicate_name}', 'dlm', ',');
    nlogp = print_dlm_line({rep_stats_rpt(is_bad_rep).ranksum_nlogp}', 'dlm', ',');
    num_outlier = nnz(is_bad_rep);
    
    recall_summary = setarrayfield(recall_summary, [],...
        {'recall_group', 'nreplicate', 'noutlier', 'outlier_name', 'nlogpval'},...
        recall_group, num_rep, num_outlier, outlier_name, nlogp);
    recall_summary = orderfields(recall_summary, ...
        orderas(fieldnames(recall_summary), {'recall_group', 'nreplicate'}));
    
    jmktbl(fullfile(out_path, 'recall_summary.txt'), recall_summary);
    h3 = mortar.compute.Recall.plotPerReplicate(rep_recall_rpt,...
        'showfig', show_fig, 'ylabelrt', recall_group);
    % Save figures and close them
    img_list = savefigures('out', out_path, 'mkdir', false, 'closefig', ~show_fig, 'exclude', h0);
    
    % create a image gallery
    index_page = fullfile(out_path, 'gallery.html');
    mkgallery(index_page, img_list, 'title', recall_group);
else
    warning('No replicates found not generating a report');
end
end

function [ds_table, ds_skipped_list] = getDSTable(ds_list)
if ischar(ds_list) && isfileexist(ds_list)
    [p, f, e] = fileparts(ds_list);
    switch lower(e)
        case '.txt'
            ds_table = parse_record(ds_list);
        case '.grp'
            file_path = parse_grp(ds_list);
            ds_table = struct('group_id', f, 'file_path', file_path);
        otherwise
            error('Expected either TXT or GRP inputs, got %s instead', e)
    end
elseif isstruct(ds_list)
    ds_table = ds_list;
elseif iscell(ds_list)
    ds_table = struct('group_id', 'CUSTOM_GROUP', 'file_path', ds_list);
else
end
req_fn = {'group_id', 'file_path'};
has_req_fn = isfield(ds_table, req_fn);
if ~all(has_req_fn)
    error('Required fields group_id and file_path missing from TXT input');
end

% check if filepaths exist
is_file = isfileexist({ds_table.file_path}');
if ~all(is_file)
    num_missing = nnz(~is_file);
    disp({ds_table(~is_file).file_path}');
    error('%d file paths dont exist, see above for a list', num_missing);
end

% check if group sizes are >1
[~, gpn, gpi, ~, gpsz] = get_groupvar(ds_table, [], 'group_id');
has_gt_1_rep = gpsz>1;
if ~all(has_gt_1_rep)
    is_singlicate = ~has_gt_1_rep;
    num_gp = length(gpn);
    num_singlicate = nnz(is_singlicate);
    if isequal(num_singlicate, num_gp)
        error('No groups have more than one replicate, cannot continue');
    else
        disp(gpn(is_singlicate));
        warning('%d / %d groups have only 1 replicate (see above for a list), ignoring', num_singlicate, num_gp)
        ds_skipped_list = gpn(is_singlicate);
        reps_to_keep = ismember(gpi, find(has_gt_1_rep));
        ds_table = ds_table(reps_to_keep);
    end
else
    ds_skipped_list = {};
end

end