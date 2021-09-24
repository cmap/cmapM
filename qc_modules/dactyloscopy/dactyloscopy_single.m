function [out_table_all, bfds] = ...
    dactyloscopy_single(det_plate_list, varargin)
%% [out_table_all, bfds] = dactyloscopy_single(det_plate_lm, varargin)
% Function to compare CMap cell lines expression profiles (fingerprints)
% with the database of of expression profiles for 1515 cell lines.
% The goal is to verify identity of a cell line in CMap experiments.
%
% Input:
%   det_plate_lm - full path to a gct structure on QNORM level containing
%               expression levels of landmark genes
%   cell_db - a gctx structure with expression profiles for the reference
%           cell lines
%   cell_db_backup - an alternative library of the reference profiles 
%           (e.g. based on the Affx profiles) that is used when a cell line 
%           on the test plate is not in the primary library (e.g. based on 
%           the RNA-Seq profiles)
%   lm_probes - a grp file with a list of all the probes for landmark genes
%   lincs_lines - a grp file with a list of all the core LINCS cell lines
%   api_url - URL to the API (must contain 'http://' prefix)
%   cell_line_dictionary - a path to a file with derived_cell_lines and
%           corresponding cell_id, it is used when an API query is empty
%   api_user_key_file - a path to a file with the API user key
%   save_out - a logical variable if any output file should be saved
%           (default value is set to: false)
%   dname_out - a directory name where all the output files will be saved
%           (default value is set to: ./dactyloscopy_output)
%   use_dmso_ony - a logical flag indicating that only wells with DMSO are
%           used (default value is set to: false and it's recommended to
%           leave it like that)
%
% Output:
%   out_table_all - summary of the results (saved to stats.txt)
%   bfds - big dactyloscopy structure that contains all the results, gct
%           structures, tables, metadata. 
% Example:
%   [x1,x2,x3,x4,x5] = dactyloscopy_single(...
%       get_gct_path('LJP006_PC3_24H_X3_B19','QNORM','/cmap/obelix/pod/custom/LJP/roast',false),...
%       '--cell_db',ds_rnaseq,...
%       '--save_out',false);
%
% E-mail: Marek Orzechowski morzech@broadinstitute.org

%% ArgsParse
pnames = {'--cell_db','--cell_db_backup','--lm_probes','--lincs_lines',...
    '--api_url','--cell_line_dictionary','--api_user_key_file',...
    '--ambiguous_clines_main','--ambiguous_clines_backup','--save_out',...
    '--dname_out','--use_dmso_only'};
dflts = {'/cmap/data/vdb/dactyloscopy/cline_rnaseq_n1022x12450.gctx',...
    '/cmap/data/vdb/dactyloscopy/cline_affx_n1515x22268.gctx',...
    '/cmap/data/vdb/dactyloscopy/lm_epsilon_n978.grp',...
    '/cmap/data/vdb/dactyloscopy/ljp_rep_lincs_lines.grp',...
    'http://api.clue.io',...
    '/cmap/data/vdb/dactyloscopy/derived_cell_lines.txt',...
    '~/.dactyloscopy.config',...
    '/cmap/data/vdb/dactyloscopy/list_of_ambiguous_cell_lines_rnaseq.txt',...
    '/cmap/data/vdb/dactyloscopy/list_of_ambiguous_cell_lines_affx.txt',...
    false,...
    './dactyloscopy_output',...
    false};

config = struct('name',pnames, 'default',dflts,...
    'help',{'A GCTX file with the reference gene expression profiles for various cell lines',...
    'A GCTX file with a backup of the reference gene expression profiles for various cell lines',...
    'A GRP file with a list of landmark genes',...
    'A GRP file with a list of LINCS cell lines',...
    'URL to API',...
    'A file with derived_cell_lines and corresponding cell_id',...
    'A file with the API user key',...
    'A file with a list of pairs of hard to distinguish cell lines for the main reference library. The file needs to contain a header but its content is arbitrary',...
    'A file with a list of pairs of hard to distinguish cell lines for the backup reference library. The file needs to contain a header but its content is arbitrary',...
    'Save output files',...
    'Directory with the output files',...
    'Use DMSO wells only'});
opt = struct('prog', mfilename, 'desc',...
    'Run dactyloscopy tool', 'undef_action','error');

args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
disp(args)

%% Assert that all the necessary files exist and all the options are set properly
cell_db=args.cell_db;
if ischar(cell_db)
    if exist(cell_db,'file')==0
        error('%s> A gct file with the reference library of cell line profiles: %s could not be found.',...
            mfilename, cell_db)
    end
end

cell_db_backup=args.cell_db_backup;
if ischar(cell_db_backup)
    if exist(cell_db_backup,'file')==0
        error('%s> A gct file with backup of the reference library of cell line profiles: %s could not be found.',...
            mfilename, cell_db_backup)
    end
end

lm_probes=args.lm_probes;
if ~isstruct(lm_probes)
    if exist(lm_probes,'file')==0
        error('%s> A grp file with a list of LM probes: %s could not be found.',...
            mfilename, ref_dist_fname)
    end
end

lincs_lines=args.lincs_lines;
if ~isstruct(lincs_lines)
    if exist(lincs_lines,'file')==0
        error('%s> A grp file with a list of core LINCS cell lines: %s could not be found.',...
            mfilename, ref_dist_fname)
    end
end

api_url = args.api_url;
if ischar(api_url)
    try
        webread(api_url);
    catch ME
        error('%s> There is a problem with connecting to the API server. See message below for details:\n%s\n',...
            mfilename, ME.message);
    end
else
    error('api_url option should be a string')
end

cell_line_dictionary=args.cell_line_dictionary;
if ischar(cell_line_dictionary)
    if exist(cell_line_dictionary,'file')==0
        error('%s> A txt file with a list of derived_cell_lines and corresponding cell_ids: %s could not be found.',...
            mfilename, cell_line_dictionary)
    end
end

api_user_key_file=args.api_user_key_file;
if ischar(api_user_key_file)
    if exist(api_user_key_file,'file')==0
        error('%s> A file with the API user key: %s could not be found.',...
            mfilename, api_user_key_file)
    end
else
    error('%s> Name of the file with the API user key needs to be provided as a string.')
end

ambiguous_clines_main=args.ambiguous_clines_main;
if ischar(ambiguous_clines_main)
    if exist(ambiguous_clines_main,'file')==0
        ambiguous_clines_main_exists = false;
        warning('%s> A file with a list of hard to distinguish pairs of cell lines for the main reference library: %s could not be found.',...
            mfilename, ambiguous_clines_main)
    else
        ambiguous_clines_main_exists = true;
    end
end

ambiguous_clines_backup=args.ambiguous_clines_backup;
if ischar(ambiguous_clines_backup)
    if exist(ambiguous_clines_backup,'file')==0
        ambiguous_clines_backup_exists = false;
        warning('%s> A file with a list of hard to distinguish pairs of cell lines for the backup reference library: %s could not be found.',...
            mfilename, ambiguous_clines_backup)
    else
        ambiguous_clines_backup_exists = true;
    end
end

save_out=args.save_out;
if ~islogical(save_out)
    error('%s> Value of save_out needs to be of logical type', mfilename)
end

if save_out
    dname_out=args.dname_out;
    mkdirnotexist(dname_out);
end

use_dmso_only=args.use_dmso_only;
if ~islogical(use_dmso_only)
    error('%s> Value of use_dmso_only needs to be of logical type', mfilename)
end
% End of assertions

%% Load API user key
    api_user_key = cell2mat(parse_grp(api_user_key_file));

%% Load the data for the plate
% get_plate_list parses det_plate_list from the input; det_plate_list could
% be a grp file or a full path to the gct file
det_plate_lm = get_plate_list(det_plate_list);

% Load a gct structure with results for an L1000 plate
ds_plate = parse_gct(det_plate_lm, 'detect_numeric', false); %detect_numeric is false so as
%to allow having cell_id = -666 as a string, and there is no need for numeric metadata
%otherwise in dactyloscopy

% Extract det_plate
det_plate = unique(ds_get_meta(ds_plate,'column','det_plate'));
if isempty(det_plate) || length(det_plate)>1
    warning('%s> det_plate is empty or has multiple values', mfilename)
    [~,fname,~] = fileparts(ds_plate.src);
    det_plate = fname;
end

%% Select only wells with DMSO (not recommended) or use all the wells
if use_dmso_only
    if logical(sum(ismember(ds_plate.chd,'pert_iname')))
        ds_plate_slice = ds_slice(ds_plate,...
            'cid',ds_plate.cid(ismember(ds_get_meta(ds_plate,'column','pert_iname'),'DMSO')));
    else
        ds_plate_slice = ds_slice(ds_plate,...
            'cid',ds_plate.cid(ismember(ds_get_meta(ds_plate,'column','pert_desc'),'DMSO')));
    end
else
    ds_plate_slice = ds_plate;
end

%% Load a gct structure with the reference profiles
ds_ref = parse_gctx(args.cell_db);
ds_ref_backup = parse_gctx(args.cell_db_backup);

% Load a list of landmark probes
lm_probes = parse_grp(args.lm_probes);

% Load a list of lincs cell lines
lincs_lines = parse_grp(args.lincs_lines);

% Slice gct structures to take only landmark genes (or whatever subset of
% lm genes was found in ds_plate) and detect cell lines missing from the
% reference library
fprintf('%s> Working on the primary refrence library\n',mfilename)
[ds_plate_slice_ref,ds_ref_slice,lincs_lines_ref] = ...
            ds_slice_and_dice(ds_plate_slice, ds_ref, lincs_lines, lm_probes);
fprintf('%s> Working on the backup refrence library\n',mfilename)
[ds_plate_slice_backup,ds_ref_backup_slice,lincs_lines_backup] = ...
            ds_slice_and_dice(ds_plate_slice, ds_ref_backup, lincs_lines, lm_probes);

%% Load the derived-parental cell line dictionary
dp_cline_dict = readtable(cell_line_dictionary,'Delimiter','\t');
if sum(ismember({'cell_id_derived_line','cell_id'},dp_cline_dict.Properties.VariableNames))~=2
    fprintf('%s> Derived-parental cell line dictionary does not contain\n',mfilename)
    fprintf('%s> columns with obligatory headers: cell_id_derived_line and cell_id\n',mfilename)
    use_dp_cline_dict = false;
else
    use_dp_cline_dict = true;
end
        
%% Load a list of ambiguous cell lines
if ambiguous_clines_main_exists 
    ambiguous_clines_main_table = readtable(ambiguous_clines_main,...
        'ReadVariableNames',false,'Header',1,'Delimiter','\t');
    ambiguous_clines_main_table.Properties.VariableNames = {'cell_id1','cell_id2','spearman_cc'};
end

if ambiguous_clines_backup_exists 
    ambiguous_clines_backup_table = readtable(ambiguous_clines_backup,...
        'ReadVariableNames',false,'Header',1,'Delimiter','\t');
    ambiguous_clines_backup_table.Properties.VariableNames = {'cell_id1','cell_id2','spearman_cc'};
end

%% Collect information about the cell_ids
% Get original cell_id
cell_ids_annot_all = ds_get_meta(ds_plate_slice,'column','cell_id');
cell_ids_annot_unique = unique(cell_ids_annot_all);

% A hack to initilize the bfds structure (to get the green square in the
% upper right corner of Matlab editor, otherwse it's not necessary to 
% initialize a structure)
tmp = cell(1,length(cell_ids_annot_unique));
[bfds(1:length(cell_ids_annot_unique)).det_plate] = tmp{:};

% A loop to run dactyloscopy for all the unique cell lines
for ii = 1:size(cell_ids_annot_unique,1)
    cell_id_annot = cell_ids_annot_unique(ii);
    fprintf('%s> Cell line in the annotation: %s\n',mfilename,cell_id_annot{1})

    sfds_primary = get_cell_line_metadata(cell_id_annot, ds_ref, ds_plate_slice,...
        lincs_lines, api_user_key, dp_cline_dict, use_dp_cline_dict);
    ambiguous_clines_table = cell2table({'','',[]},'VariableNames',...
                        {'cell_id1','cell_id2','spearman_cc'});

    if sfds_primary.cell_line_is_member
        sfds = sfds_primary;
        ds_plate_slice = ds_plate_slice_ref;
        ds_ref_lm = ds_ref_slice;
        lincs_lines = lincs_lines_ref;
        if ambiguous_clines_main_exists
            ambiguous_clines_table = ambiguous_clines_main_table;
        end
        selected_ref_db = 'main';
        %lm_probes = lm_probes_ref;
        fprintf('%s> Using main reference library.\n\n', mfilename)
    else
        sfds_backup = get_cell_line_metadata(cell_id_annot, ds_ref_backup, ds_plate_slice,...
        lincs_lines, api_user_key, dp_cline_dict, use_dp_cline_dict);
        if sfds_backup.cell_line_is_member
            sfds = sfds_backup;
            ds_plate_slice = ds_plate_slice_backup;
            ds_ref_lm = ds_ref_backup_slice;
            lincs_lines = lincs_lines_backup;
            if ambiguous_clines_backup_exists
                ambiguous_clines_table = ambiguous_clines_backup_table;
            end
            selected_ref_db = 'backup';
            fprintf('%s> Using backup reference library.\n\n',mfilename)
        else
            sfds = sfds_primary;
            ds_plate_slice = ds_plate_slice_ref;
            ds_ref_lm = ds_ref_slice;
            lincs_lines = lincs_lines_ref;
            if ambiguous_clines_main_exists
                ambiguous_clines_table = ambiguous_clines_main_table;
            end
            selected_ref_db = 'main';
            fprintf('%s> The cell line: %s is missing from both reference libraries.\n',...
                mfilename, cell_id_annot{1}) 
            fprintf('%s> Falling back to the main one.\n\n',mfilename)
        end
    end
    
    % A structre cl contains all the information collected in this loop
    bfds(ii).det_plate = det_plate;
    bfds(ii).cell_id_annot = cell_id_annot;
    bfds(ii).cell_id = sfds.cell_id;
    bfds(ii).cell_lineage = sfds.cell_lineage;
    bfds(ii).cell_histology = sfds.cell_histology;
    bfds(ii).cell_line_is_guessed = sfds.cell_line_is_guessed;
    bfds(ii).cell_line_is_missing = sfds.cell_line_is_missing;
    bfds(ii).cell_line_is_lincs = sfds.cell_line_is_lincs;
    bfds(ii).selected_ref_db = selected_ref_db;
    bfds(ii).ds_plate_slice = ds_plate_slice;
    bfds(ii).ds_ref_lm = ds_ref_lm;
    bfds(ii).lincs_lines = lincs_lines;
end

out_table_all = {};

%% A loop over the cell lines starts here
for ii = 1:length(bfds)
    [ds_cc,ds_rank,ds_cc_lincs,ds_rank_lincs,ds_median,ds_median_lincs,...
        cc_sorted_median,cc_sorted_median_table,cc_sorted_median_lincs,... 
        cc_sorted_median_lincs_table] =...
        calculate_cc_and_rank(bfds(ii).det_plate,bfds(ii).ds_plate_slice,...
        bfds(ii).ds_ref_lm,...
        cell_ids_annot_all,bfds(ii).cell_id_annot,bfds(ii).lincs_lines);

    bfds(ii).ds_cc = ds_cc;
    bfds(ii).ds_rank = ds_rank;
    bfds(ii).ds_cc_lincs = ds_cc_lincs;
    bfds(ii).ds_rank_lincs = ds_rank_lincs;
    bfds(ii).ds_median = ds_median;
    bfds(ii).ds_median_lincs = ds_median_lincs;
    bfds(ii).cc_sorted_median = cc_sorted_median;
    bfds(ii).cc_sorted_median_table = cc_sorted_median_table;
    bfds(ii).cc_sorted_median_lincs = cc_sorted_median_lincs;
    bfds(ii).cc_sorted_median_lincs_table = cc_sorted_median_lincs_table;
    bfds(ii).best_cell_id = bfds(ii).cc_sorted_median(1,1);
    bfds(ii).best_lineage = bfds(ii).cc_sorted_median(1,3);
    bfds(ii).best_lincs_cell_id = bfds(ii).cc_sorted_median_lincs(1,1);
    bfds(ii).best_lincs_lineage = bfds(ii).cc_sorted_median_lincs(1,3);
    
    % Sort by median for plots
    %[~,bfds(ii).sidx] = sort(median(bfds(ii).ds_rank.mat,2));
    %[~,bfds(ii).lidx] = sort(median(bfds(ii).ds_rank_lincs.mat,2));
    [~,bfds(ii).sidx,~] = map_ord(bfds(ii).ds_cc.rid,...
        bfds(ii).cc_sorted_median_table.cell_id);
    [~,bfds(ii).lidx,~] = map_ord(bfds(ii).ds_cc_lincs.rid,...
        bfds(ii).cc_sorted_median_lincs_table.cell_id);
    
    % Construct bfds (very big structure) to return in the output
    if bfds(ii).cell_line_is_missing
        bfds(ii).rank_pos = {'missing'};
        bfds(ii).rank_pos_lincs = {'non-lincs'};
        %bfds(ii).rank_pos = {'-666'};
        %bfds(ii).rank_pos_lincs = {'-666'};
        bfds(ii).rank_per_well_table = {'-666'};
        bfds(ii).dactyloscopy_pass = false;
        bfds(ii).is_ambig = false;
    else
        bfds(ii).rank_pos = num2cell(...
            find(ismember(bfds(ii).cc_sorted_median(:,1),bfds(ii).cell_id)==1, 1, 'first'));
        
        if bfds(ii).cell_line_is_lincs
            bfds(ii).rank_pos_lincs = num2cell(...
                find(ismember(bfds(ii).cc_sorted_median_lincs(:,1),bfds(ii).cell_id)==1, 1, 'first'));
        else
            bfds(ii).rank_pos_lincs = {'non-lincs'};
        end
        
        bfds(ii).rank_per_well_table = cell2table([bfds(ii).ds_rank.cid';...
            ds_get_meta(bfds(ii).ds_rank,'column','det_well')';...
            num2cell(bfds(ii).ds_rank.mat(ismember(bfds(ii).ds_rank.rid,bfds(ii).cell_id),:))]',...
            'VariableNames',{'det_plate','rna_well','rank'});
        
        if bfds(ii).rank_pos{1}==1
            bfds(ii).dactyloscopy_pass = true;
            bfds(ii).is_ambig = false;
        else
            if bfds(ii).rank_pos_lincs{1} == 1
                bfds(ii).dactyloscopy_pass = true;
                bfds(ii).is_ambig = false;
            else
                bfds(ii).dactyloscopy_pass = false;
                bfds(ii).is_ambig = find_ambiguous_clines(bfds(ii).cell_id,...
                    bfds(ii).best_cell_id{1},bfds(ii).best_lincs_cell_id{1},...
                    ambiguous_clines_table);
            end
        end
    end
    % Construct a cell array and a table with a summary of dactyloscopy.
    % The summary table is saved to the stats file.
    bfds(ii).out = {bfds(ii).det_plate{1}, bfds(ii).cell_id_annot{1}, ...
        bfds(ii).cell_lineage,...
        bfds(ii).cell_id, bfds(ii).cell_line_is_guessed, ...
        bfds(ii).cell_line_is_missing, bfds(ii).cell_line_is_lincs,...
        bfds(ii).rank_pos{1}, bfds(ii).rank_pos_lincs{1}, ...
        bfds(ii).best_cell_id{1}, bfds(ii).best_lineage{1}, ...
        bfds(ii).best_lincs_cell_id{1}, bfds(ii).best_lincs_lineage{1}, ...
        bfds(ii).selected_ref_db,...
        bfds(ii).dactyloscopy_pass,bfds(ii).is_ambig};
    
    bfds(ii).out_table = cell2table(num2cell(bfds(ii).out),...
        'VariableNames',...
        {'det_plate','cell_id_annot','cell_lineage_annot',...
        'cell_id','is_guessed','is_missing','is_lincs',...
        'rank','rank_lincs', ...
        'cell_id_best','best_lineage', ...
        'cell_id_lincs_best','lincs_best_lineage', ...
        'selected_ref_db','dactyloscopy_pass','is_ambiguous'});
    
    out_table_all = [out_table_all; bfds(ii).out_table];
    
    % Save files for each of the cell lines on the plate
    if args.save_out
        % Save individual output tables
        writetable(bfds(ii).out_table, fullfile(dname_out,...
            strcat('dactyloscopy_test_',bfds(ii).cell_id_annot{1},'.txt')),...
            'Delimiter','\t')
        % Save ds with Spearman CC for all the wells and
        % all the reference cell lines to a gct file
        disp(strcat('ds_cc_',bfds(ii).cell_id_annot{1},'.gct'))
        mkgct(fullfile(dname_out,...
            strcat('ds_cc_',bfds(ii).cell_id_annot{1},'.gct')), ...
            ds_slice(bfds(ii).ds_cc,'rid',bfds(ii).ds_cc.rid(bfds(ii).sidx)))
        
        % Save ds with a rank list for all the wells and
        % all the reference cell lines to a gct file
        mkgct(fullfile(dname_out,...
            strcat('ds_rank_',bfds(ii).cell_id_annot{1},'.gct')), ...
            ds_slice(bfds(ii).ds_rank,'rid',bfds(ii).ds_rank.rid(bfds(ii).sidx)))
        
        % Save ds with Spearman CC for all the wells and
        % the core LINCS reference cell lines to a gct file
        
        % Save ds with a rank list for all the wells and
        % the core LINCS reference cell lines to a gct file
        
    end
end

% Print final result
fprintf('%s> Results\n\n', mfilename)
disp(out_table_all)

%% Save output files
if args.save_out
    % Save a table with stats
    writetable(out_table_all,...
        fullfile(dname_out, 'dactyloscopy_test.txt'), 'Delimiter','\t')
end

end
