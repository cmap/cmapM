function build(varargin)
% BUILD Collate signatures and metadata from brew folders

if nargin<1
    warning('No arguments supplied')
    varargin={'-h'};
end
import mortar.util.Message
[args, help_flag] = get_args(varargin{:});

if ~help_flag
    
    t0 = tic;
    % instance level data
    instance_location = args.brew_root;
    
    % brew level data
    brew_location = fullfile(instance_location, args.brew_group);

    % check if required files exist
    file_rpt = checkFiles(args, brew_location, instance_location);
    if any(strcmp('FAIL', {file_rpt.file_status}'))
        out_file = fullfile(args.out, 'file_status.txt');
        jmktbl(out_file, file_rpt);
        error('FILECHECK FAILURE: Some required files were missing See %s for a list', out_file);
    end
    
    % parse dose_list
    if ~isempty(args.dose_list)
        dose_list_um = parse_grp(args.dose_list);
        dose_list_um = str2double(dose_list_um);
        assert(all(~isnan(dose_list_um)), 'Expected non-NaN doses in dose_list');
    end
    
    % fields corresponding to treatment dose
    dose_fields = tokenize(args.dose_fields, ',', true);
    % create an idose_field for each dose_field 
    idose_fields = cellfun(@convert_to_idose, dose_fields, 'unif', false);
    
    %% merge MODZ files
    
    if ~isempty(args.custom_chip)
        chip_info = parse_record(args.custom_chip, 'detect_numeric', false);
        required_chip_fields = {'pr_id', 'pr_gene_id', 'pr_is_lm', 'pr_is_bing'};
        assert(has_required_fields(chip_info, required_chip_fields),...
            true, 'Missing required fields from custom chip file');        
    else
        chip_info = mortar.common.Chip.get_chip(args.feature_platform, args.feature_space);
    end
    feature_space = {chip_info.pr_id}';
    Message.debug(args.verbose, 'Using features: %s (%s)',args.feature_platform, args.feature_space);
    
    Message.debug(args.verbose, 'Merging Level 5 (%s)', args.level_5_file_pattern);
    cs = merge_folder_dataset('plate', args.brew_list,...
        'plate_path', args.brew_path,...
        'dstype', args.level_5_file_pattern,...
        'rid', feature_space,...
        'row_filter', args.row_filter,...
        'column_filter', args.column_filter,...
        'location', brew_location);
    
    %% Level 3
    if ~args.do_quick_build
        Message.debug(args.verbose, 'Merging Level 3 (%s)', args.level_3_file_pattern);
        qn = merge_folder_dataset('plate',args.brew_list,...
            'plate_path', args.brew_path,...
            'dstype', args.level_3_file_pattern,...
            'rid', feature_space,...
            'row_filter', args.row_filter,...
            'column_filter', args.column_filter,...
            'location', instance_location);
        
        %% Level 4
        % we could make this more sophisticated but for now just put
        % an asterisk in place
        Message.debug(args.verbose, 'Merging Level 4 (%s)', args.level_4_file_pattern);
        zspc = merge_folder_dataset('plate',args.brew_list,...
            'plate_path', args.brew_path,...
            'dstype', args.level_4_file_pattern,...
            'rid', feature_space,...
            'row_filter', args.row_filter,...
            'column_filter', args.column_filter,...
            'location', instance_location);
        [~, cidx] = intersect_ord(zspc.cid, qn.cid);
        assert(isequal(qn.cid, zspc.cid(cidx)));
        zspc = ds_slice(zspc,'cid',zspc.cid(cidx));
    end
    %% Output feature-ids
    is_lm = strcmp('1', {chip_info.pr_is_lm}');
    is_bing = strcmp('1', {chip_info.pr_is_bing}');
    Message.debug(args.verbose, 'Output feature_ids as: %s', args.feature_id);
    switch (args.feature_id)
        case 'probeset_id'
            % Already in probeset space, do nothing to the datasets
            lm_space = {chip_info(is_lm).pr_id}';
            bing_space = {chip_info(is_bing).pr_id}';
            gene_info = chip_info;
        case 'gene_id'
            cs = mortar.compute.MapFeatures.convertL1000Dataset(cs, chip_info);
            if ~args.do_quick_build
                qn = mortar.compute.MapFeatures.convertL1000Dataset(qn, chip_info);
                zspc = mortar.compute.MapFeatures.convertL1000Dataset(zspc, chip_info);
            end
            lm_space = {chip_info(is_lm).pr_gene_id}';
            bing_space = {chip_info(is_bing).pr_gene_id}';
            gene_info = rmfield(chip_info, 'pr_id');
            gene_info = orderfields(gene_info,...
                orderas(fieldnames(gene_info), 'pr_gene_id'));
    end
    
    %% SIGINFO
    Message.debug(args.verbose, 'Extracting Signature annotations');
    annot_sig = gctmeta(cs);
    annot_sig = mvfield(annot_sig, 'cid', 'sig_id');
    % remove row and column annotations
    cs = ds_strip_meta(cs);
    % brew prefix
    brew_prefix = cellfun(@(x) x{1}, tokenize({annot_sig.sig_id}',':'),'uniformoutput', false);
    % convert distil_id to array
    distil_id = tokenize({annot_sig.distil_id}', '|');
    annot_sig = setarrayfield(annot_sig, [], {'brew_prefix', 'distil_id'}, brew_prefix, distil_id);
    
    %% genesets
    if ~args.do_quick_build
        Message.debug(args.verbose, 'Generating genesets');
        % Landmark
        cs_lm = ds_slice(cs, 'rid', lm_space, 'ignore_missing', true);
        [up50_lm, dn50_lm] = get_genesets(cs_lm, 50, 'descend');
        
        % BING
        cs_bing = ds_slice(cs, 'rid', bing_space, 'ignore_missing', true);
        [up100_bing, dn100_bing] = get_genesets(cs_bing, 100, 'descend');
        
        % AIG
        [up100_aig, dn100_aig] = get_genesets(cs, 100, 'descend');
    end
    %% pct_self_rank_q25, ngenes modulated
    brew_list = parse_grp(args.brew_list);
    nb = length(brew_list);
    for ii=1:nb
        self_conn_file = fullfile(args.brew_path, brew_list{ii}, fullfile(brew_location, 'self_conn', 'self_connections.txt'));
        sig_stats_file = fullfile(args.brew_path, brew_list{ii}, fullfile(brew_location, 'sigstat', sprintf('%s_SIGSTATS.txt', brew_list{ii})));
        self_conn = parse_record(self_conn_file);
        sig_stats = parse_record(sig_stats_file, 'detect_numeric', false);
        
        pct_self_rank_q25 = 100*([self_conn.rank_q25]'-1)./([self_conn.ninstance]'-1);
        pct_self_rank_q25(pct_self_rank_q25 < 0) = -666;
        self_conn = setarrayfield(self_conn, [], 'pct_self_rank_q25', pct_self_rank_q25);
        
        sig_stats = mvfield(sig_stats, {'nup', 'ndn'}, {'ngenes_modulated_up_inf', 'ngenes_modulated_dn_inf'});
        annot_sig = join_table(annot_sig, self_conn, 'sig_id', 'id',...
            {'pct_self_rank_q25'});
        annot_sig = join_table(annot_sig, sig_stats, 'sig_id', 'id',...
            {'ngenes_modulated_up_inf', 'ngenes_modulated_dn_inf'});
    end
    %% collate zstats_well if available
    zs_fields = {'tgt_gene_zs', 'tgt_gene_row_rank'};
    for ii=1:nb
        zstats_well_file = fullfile(args.brew_path, brew_list{ii}, fullfile(brew_location, 'gposcon', 'zstats_well.txt'));
        has_gp_field = all(isfield(annot_sig, zs_fields));
        if isfileexist(zstats_well_file)
            Message.debug(args.verbose, 'Collating gposcon results from : %s', zstats_well_file);
            zstats_well = parse_record(zstats_well_file);
            zstats_well = mvfield(zstats_well, {'zs', 'rank'}, zs_fields);
            annot_sig = join_table(annot_sig, zstats_well, 'sig_id', 'sample_id',...
                zs_fields);
        elseif has_gp_field
            warning('ZSTATS_WELL file not found, skipping: %s', zstats_well_file);
        end
    end
    %% Ranks
    if ~args.do_quick_build
        Message.debug(args.verbose, 'Computing ranks');
        rank_aig = score2rank(cs);
        rank_bing = score2rank(cs_bing);
        rank_lm = score2rank(cs_lm);
    end
    %% INSTINFO
    if ~args.do_quick_build
        Message.debug(args.verbose, 'Extracting instance annotations');
        annot_inst = cell2struct([qn.cid, ds_get_meta(qn, 'column', qn.chd)]', [{'distil_id'}; qn.chd]);
        toks = tokenize({annot_inst.det_plate}, '_');
        toks = cat(2, toks{:})';
        [annot_inst.pert_plate] = toks{:,1};
        
        % QNORM remove column and row annotations
        qn = ds_strip_meta(qn);
        
        % ZS remove column and row annotations
        zspc = ds_strip_meta(zspc);
    end
    %% Discretize pert_idose if specified        
    nfield = length(dose_fields);
    for ii=1:nfield
        this_field = dose_fields{ii};
        this_idose_field = idose_fields{ii};
        has_pert_dose = isfield(annot_sig, this_field);
        if ~isempty(args.dose_list) && has_pert_dose
            Message.debug(args.verbose, 'Discretizing pert_idose with provided dose_list');
            sig_pert_dose = [annot_sig.(this_field)]';
            [~, sig_pert_idose, sig_delta] = discretize_doses(sig_pert_dose, dose_list_um, args.dose_tolerance, '%2.4g');
            annot_sig = setarrayfield(annot_sig, [], this_idose_field, sig_pert_idose);
            if ~args.do_quick_build && isfield(annot_inst, this_field);
                inst_pert_dose = [annot_inst.pert_dose]';
                [~, inst_pert_idose, inst_delta] = discretize_doses(inst_pert_dose, dose_list_um, args.dose_tolerance, '%2.4g');
                annot_inst = setarrayfield(annot_inst, [], this_idose_field, inst_pert_idose);
            end
        end
    end

    %% save datasets
    Message.debug(args.verbose, 'Saving Data matrices');
    mkgctx(fullfile(args.out,'modzs.gctx'), cs);
    if ~args.do_quick_build
        mkgctx(fullfile(args.out,'q2norm.gctx'), qn);
        mkgctx(fullfile(args.out,'zspc.gctx'), zspc);
        mkgctx(fullfile(args.out,'rank_aig.gctx'), rank_aig);
        mkgctx(fullfile(args.out,'rank_bing.gctx'), rank_bing);
        mkgctx(fullfile(args.out,'rank_lm.gctx'), rank_lm);
    end
    %% save annotation tables
    Message.debug(args.verbose, 'Saving annotations');
    
    % Feature info
    mktbl(fullfile(args.out, 'geneinfo.txt'), gene_info);
    mktbl(fullfile(args.out, 'siginfo.txt'), annot_sig);
    
    if ~args.do_quick_build
        % signature metadata statistics
        sig_stats = get_sig_stats(annot_sig);
        
        mktbl(fullfile(args.out, 'instinfo.txt'), annot_inst);
        savejson('', sig_stats, fullfile(args.out, 'sigstats.json'));
        
        % genesets
        Message.debug(args.verbose, 'Saving genesets');
        mkgmt(fullfile(args.out, 'up50_lm.gmt'), up50_lm);
        mkgmt(fullfile(args.out, 'dn50_lm.gmt'), dn50_lm);
        
        mkgmt(fullfile(args.out, 'up100_bing.gmt'), up100_bing);
        mkgmt(fullfile(args.out, 'dn100_bing.gmt'), dn100_bing);
        
        mkgmt(fullfile(args.out, 'up100_aig.gmt'), up100_aig);
        mkgmt(fullfile(args.out, 'dn100_aig.gmt'), dn100_aig);
        
        % sig_id and distil_id lists
        Message.debug(args.verbose, 'Saving id lists');
        mkgrp(fullfile(args.out, 'sig_id.grp'), {annot_sig.sig_id}');
        mkgrp(fullfile(args.out, 'distil_id.grp'), {annot_inst.distil_id}');
    end
    Message.debug(args.verbose, 'Done in %2.1 s', toc(t0));
end
end

function rpt = checkFiles(args, brew_location, instance_location)
% Check if required files exist
brew_list = parse_grp(args.brew_list);
nb = length(brew_list);
rpt = struct('brew_id', brew_list,...
       'level5_file', '',...
       'level4_file', '',...
       'level3_file', '',...
       'self_conn_file', '',...
       'sig_stats_file', '',...
       'missing_files', 'None',...
       'file_status', 'PASS');
file_labels = {'LEVEL5', 'LEVEL4', 'LEVEL3', 'SELFCONN', 'SIGSTATS'};   
for ii=1:nb
    % check level5
    level_5_pat = fullfile(args.brew_path, brew_list{ii},...
                        fullfile(brew_location,...
                        sprintf('%s_%s*.gct*',...
                            brew_list{ii}, args.level_5_file_pattern)));
    % check level4
    level_4_pat = fullfile(args.brew_path, brew_list{ii},...
                        fullfile(instance_location,...
                        sprintf('%s_%s*.gct*',...
                        brew_list{ii}, args.level_4_file_pattern)));
    
    % check level3
    level_3_pat = fullfile(args.brew_path, brew_list{ii},...
                        fullfile(instance_location,...
                        sprintf('%s_%s*.gct*',...
                        brew_list{ii}, args.level_3_file_pattern)));
                    
    % check metadata
    self_conn_pat = fullfile(args.brew_path, brew_list{ii},...
                            fullfile(brew_location, 'self_conn', 'self_connections.txt'));
    sig_stats_pat = fullfile(args.brew_path, brew_list{ii},...
                            fullfile(brew_location, 'sigstat', sprintf('%s_SIGSTATS.txt', brew_list{ii})));
    
    file_pat = {level_5_pat; level_4_pat; level_3_pat; self_conn_pat; sig_stats_pat};
    file_paths = find_file_patterns(file_pat);
    is_file_exist = isfileexist(file_paths);
    if ~all(is_file_exist)
        file_status = 'FAIL';
        missing_files = file_labels(~is_file_exist);
    else
        file_status = 'PASS';
        missing_files = 'None';
    end
    rpt = setarrayfield(rpt, ii, {'level_5_file', 'level_4_file',...
                            'level_3_file', 'self_conn_file',...
                            'sig_stats_file', 'missing_files',...
                            'file_status'},...
                  file_paths{1}, file_paths{2}, file_paths{3},...
                  file_paths{4}, file_paths{5}, missing_files, file_status);    
end
end

function file_paths = find_file_patterns(pat)
npat = length(pat);
file_paths = cell(npat, 1);
for ii=1:npat
    [fn, fp] = find_file(pat{ii});
    if isequal(length(fn),1)
        file_paths{ii} = fp{1};
    elseif ~isempty(fn)
        disp(fp)
        error('Multiple entries found for %s', pat{ii});
    else
        error('%s not found', pat{ii})
    end
end
end

function v = get_field(s, f, data_type, exclude_val)
% GET_FIELD get a field from a structure array
cast_to_string = strcmpi(data_type, 'char');
if ~(isfield(s, f))
    warning('Field %s not found', f)
    v = {};
else
    v = {s.(f)}';
    if mortar.util.DataType.isCellNumeric(v)
        if cast_to_string
            v = cellfun(@stringify, v, 'unif', false);
            is_str = true;
        else
            is_str = false;
            v = cell2mat(v);
        end
    else
        if ~cast_to_string
            is_str = false;
            v = str2double(v);
        else
            is_str = true;
        end
    end
    v = v(~ismember(v, exclude_val));
end
end

function sig_stats = get_sig_stats(sinfo)
% GET_SIG_STATS get frequency info for a build

num_sig = length(unique(get_field(sinfo, 'sig_id', 'char', '-666')));
num_pert = length(unique(get_field(sinfo, 'pert_id', 'char', '-666')));
num_cell = length(unique(get_field(sinfo, 'cell_id', 'char', '-666')));
num_dose = length(unique(get_field(sinfo, 'pert_idose', 'char', '-666')));
num_time_point = length(unique(get_field(sinfo, 'pert_itime', 'char', '-666')));
% median number of replicates
num_replicate = median(get_field(sinfo, 'distil_nsample', 'double', -666));
[pt, npt] = getcls(get_field(sinfo, 'pert_type', 'char', '-666'));
num_pt = accumarray(npt, ones(size(npt)));
[~, imax] = max(num_pt);
% predominant perturbagen type
modal_pert_type = pt{imax};

sig_stats = struct('num_signature', num_sig,...
    'num_perturbagen', num_pert,...
    'num_cell_line', num_cell,...
    'num_dose', num_dose,...
    'num_time_point', num_time_point,...
    'num_replicate', num_replicate,...
    'modal_pert_type', modal_pert_type);

end

function [args, help_flag] = get_args(varargin)

ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'Build brew signatures', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    % work dir
    if args.create_subdir
        wkdir = mktoolfolder(args.out, mfilename, 'prefix', args.rpt);
    else
        if isempty(args.out)
            args.out = pwd;
        end
        wkdir = args.out;
        if ~isdirexist(wkdir)
            mkdir(wkdir);
        end
    end
    
    args_save = args;
    % handle remote URLs
    args = get_config_url(args, wkdir, true);
    
    % save config with remote URLS if applicable
    WriteYaml(fullfile(wkdir, 'config.yaml'), args_save);
    args.out = wkdir;
end
end

function idose_field = convert_to_idose(dose_field)
% CONVERT_TO_IDOSE convert a dose_field string into a pert_idose string
% e.g. pert_2_dose --> pert_2_idose
% e.g. pert_dosage --> pert_dosage_idose (if the name is unorthodox,
% 'idose' is simply appended
if isempty(strfind(dose_field, 'dose'))
    idose_field = strcat(dose_field, '_idose');
else
    idose_field = strrep(dose_field, 'dose', 'idose'); 
end
end
