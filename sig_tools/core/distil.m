function [sig, perm_zs, perm_stat] = distil(ds, varargin)
% DISTIL Compute summarized signatures from replicate data.
%
% [SIG, PERM_ZS, PERM_STAT] = DISTIL(DS) Uses moderated-zscore with default
% parameters on Level 4 dataset DS (usually z-scored data with replicates)
% 
% 'metric': {'modz', 'avgz', 'medianz', 'stoufz'} summarization metric.
%             Corresponds to Moderated z-score, Mean, Median, Stouffer's
%             z-score respectively. Default is 'modz'
% 'modz_metric': {'wt_avg', 'wt_stouffer'} Moderated z-score variant.
%              Default is wt_avg
% 'group_by' : string, comma separated string specifying column (sample)
%              grouping variables. Samples of each unique group are
%              summarized. Default is 'cell_id,pert_time,pert_id'
% 'clip_range': [LO val, HI val] numeric array, If not Inf clips the range
%                of the input signal to be [LO, HI]. Default is [-10, 10]
% 'clip_low_wt': boolean, if true sets modz weights <0.01 to 0.01. 
%               Default is true
% 'clip_low_cc': boolean, if true sets negative pairwise spearman correlation values
%               to zero. Default is true
% 'out' : string, output path. If not empty saves the results to disk. Default is ''
% 'name' : string, output prefix used to save files to disk. Default is ''
% 'del_affx_ctl': boolean, If true excludes features that begin with AFFX.
%                 Default is false
% 'use_gctx': boolean, If true saves results to binary GCTX files,
%             otherwise saves to text GCT files. Default is true
% 'debug': boolean, Print debugging information if true. Default is true
% 'cid': cell string array or GRP file of column ids of the dataset, If not
%        empty, slices the specified columns before applying the algorithm.
%        Default is ''
% 'cid_prefix': string, If not empty, prepends the string to the column ids
%               of the output matrix. Default is ''
% 'pert_desc_field': 'pert_mfc_desc'
% 'ssn': integer, Number of features to use to compute signature strength.
%        Default is 100
% 'ss_ngene_cutoff': float scalar, z-score threshold to use to compute
%                    signature strength ss_ngene Default is 2
%
% 'corr_space' : cell string array or GRP file of row ids of the dataset,
%              used to compute pairwise correlations for the MODZ weights.
% See Also: DISTIL_CORE, MODZ

%TOFIX: only accepts datasets parsed with 'detect_numeric' set to false.

pnames = {'out', 'name', ...
    'clip_range', 'metric', 'group_by',...
    'del_affx_ctl','use_gctx', 'debug',...
    'clip_low_wt','cid_prefix','modz_metric',...
    'ssn', 'ss_ngene_cutoff', 'clip_low_cc', 'pert_desc_field',...
    'cid', 'corr_space', 'feature_desc_field', 'landmark_field'};
dflts = {'', '', ...
    [-10, 10], 'modz', 'cell_id,pert_time,pert_id',...
    false, true, true,...
    true, '', 'wt_avg',...
    100, 2, true, 'pert_iname',...
    '', '', 'pr_gene_symbol', 'pr_is_lmark'};
args = parse_args(pnames, dflts, varargin{:});

if ischar(ds) && isfileexist(ds)
    ds = parse_gctx(ds, 'detect_numeric', false,...
                    'annot_precision', inf,...
                    'cid', args.cid);
elseif ~isstruct(ds)
    error ('distil:InvalidInput', 'ds is not valid')
end

if isempty(args.name)
    [~,f] =  fileparts(ds.src);
    args.name = regexprep(f, '_n[0-9]*x[0-9]*$','');
end

if args.use_gctx
    gct_writer = @mkgctx;
else
    gct_writer = @mkgct;
end

if ~isinf(args.clip_range)
    % threshold zscores
    dbg(args.debug, 'Clipping scores to [%2g, %2g]',args.clip_range(1), args.clip_range(2));
    ds.mat = clip(ds.mat, args.clip_range(1), args.clip_range(2));
end
nf = size(ds.mat);
if isempty(args.corr_space)
    % Default is to find lm genes
    feature_desc = ds_get_meta(ds, 'row', args.feature_desc_field);
    is_lm_val = ds_get_meta(ds, 'row', args.landmark_field);
    if isnumeric(is_lm_val)
        islmark = is_lm_val > 0;
    else
        islmark = strcmpi('y', is_lm_val) | strcmpi('1', is_lm_val);
    end
    dbg(args.debug, 'Found %d landmarks', nnz(islmark));
    % need indices for modzs
    lmidx = find(islmark);
    lmgene = unique(feature_desc(islmark));
else
    % Use custom feature space for computing correlations
    feature_desc = ds_get_meta(ds, 'row', args.feature_desc_field);
    corr_space = parse_grp(args.corr_space);
    islmark = ismember(ds.rid, corr_space);
    lmidx = find(islmark);
    lmgene = unique(feature_desc(islmark));    
end

%% Feature space
% discard AFFX control probes
if args.del_affx_ctl
    feature_idx = cellfun(@isempty, regexp(ds.rid, 'AFFX'));
else
    feature_idx = 1:nf;
end
nfeature = nnz(feature_idx);

pert_type = parse_grp(fullfile(get_l1k_path('dic_path'), 'pert_type.dic'));
pert_type = setdiff(pert_type, {'lma_x'});
search_type = {print_dlm_line(pert_type, 'dlm', '|')};

% unique cell types
search_cell = ds_get_meta(ds, 'column', 'cell_id', true);
% nc = length(search_cell);
% unique time points
if ds.cdict.isKey('pert_time') && any(cellfun(@isnumeric, ds.cdesc(:,ds.cdict('pert_time'))))
    % filter_table needs strings
    ds.cdesc(:,ds.cdict('pert_time')) = num2cellstr(cell2mat(ds.cdesc(:, ds.cdict('pert_time'))));
    search_time = unique(ds.cdesc(:, ds.cdict('pert_time')));
end

[keep_desc, keep_idx] = filter_table(ds.cdesc, ...
    {'pert_type'}, ...
    search_type, 'tblhdr', ds.chd);
nkeep = length(keep_idx);
if nkeep>0
    [group_var, group_id, group_idx] = get_groupvar(keep_desc, ds.chd, args.group_by,'add_unit',false);

    ng = length(group_id);
    sig_mat = zeros(nfeature, ng);
    sig_cid = cell(ng, 1);
    %additional signature specific fields
    new_fields = {'distil_metric';...
        'distil_id'; ...
        'distil_wt';...
        'distil_cc_max';...
        'distil_cc_median';...
        'distil_cc_q75';...
        'distil_ss';...
        'distil_ss_ngene';...
        'distil_tas';...
        'distil_ss_cutoff';...
        'distil_cc_cutoff';...
        'distil_nsample';...
        'islmark'};
    sigfn = unique([ds.chd; new_fields]);
    sigann = cell(ng, length(sigfn));
    sigdict = containers.Map(sigfn, 1:length(sigfn));
    col_cc_q75 = zeros(ng,1);
    dbg(args.debug, 'Computing signatures using %s', args.metric);
    for g = 1:ng
        % Exact match for each group_id
        sig_idx = find(group_idx==g);
        sig_desc = keep_desc(sig_idx, :);

        pert_desc = unique(sig_desc(:,ds.cdict(args.pert_desc_field)));
        if isempty(args.cid_prefix)
            sig_cid{g} =  print_dlm_line(upper(group_id(g)), 'dlm', ':');
        else
            sig_cid{g} = print_dlm_line(upper({args.cid_prefix, group_id{g}}), 'dlm', ':');
        end
        % fix for spaces
        sig_cid{g} = regexprep(sig_cid{g},' +','_');
        % sample index in ds
        samp_idx = keep_idx(sig_idx);
        zs = ds.mat(feature_idx, samp_idx);
        [sig_mat(:, g), samp_wt, cc] = distil_core(zs, lower(args.metric), ...
            lmidx, ...
            args.clip_low_wt,...
            args.clip_low_cc,...
            args.modz_metric);
        % correlation stats
        repcc = tri2vec(cc);
        repstat = describe(repcc);
        cc_max = ifempty(repstat.max, -666);
        cc_median = ifempty(repstat.median, -666);
        if isempty(repstat.fivenum)
            cc_q75 = -666;
        else
            cc_q75 = repstat.fivenum(4);
        end
        col_cc_q75(g) = cc_q75;
        % Signature annotations
        sigann{g, sigdict('distil_metric')} = lower(args.metric);
        sigann{g, sigdict('distil_id')} = ...
            print_dlm_line(ds.cid(samp_idx), 'dlm', '|');
        sigann{g, sigdict('distil_wt')} = ...
            print_dlm_line(samp_wt, 'dlm', ',', 'precision', 2);
        sigann{g, sigdict('distil_cc_max')} = ...
            print_dlm_line(cc_max, 'dlm', ',', 'precision', 2);
        sigann{g, sigdict('distil_cc_median')} = ...
            print_dlm_line(cc_median, 'dlm', ',', 'precision', 2);
        sigann{g, sigdict('distil_cc_q75')} = ...
            print_dlm_line(cc_q75, 'dlm', ',', 'precision', 4);
        sigann{g, sigdict('distil_nsample')} = length(sig_idx);
        sigann{g, sigdict('islmark')} = max(ismember(pert_desc, lmgene));
        % add merged fields of existing annotations
        old_fields = setdiff(ds.chd, new_fields);
        for ii=1:length(old_fields)
            ann = ds.cdesc(samp_idx, ds.cdict(old_fields{ii}));
            % make sure to cast as string
            ann = unique(cellfun(@num2str, ann, 'UniformOutput', false));
            uniqann = unique(ann);
            if length(uniqann)>1
                sigann{g, sigdict(old_fields{ii})} = print_dlm_line(ann, 'dlm', '|', 'precision', 1);
            else
                sigann(g, sigdict(old_fields{ii})) = uniqann;
            end
        end
        dbg(args.debug, '%s islmark:%d numrep:%d', sig_cid{g}, sigann{g, sigdict('islmark')}, length(samp_idx))
    end

    sig = mkgctstruct(sig_mat, 'cid', sig_cid, 'chd', sigfn, 'cdesc', sigann, ...
        'rid', ds.rid(feature_idx), 'rhd', ds.rhd, 'rdesc', ds.rdesc(feature_idx,:));

    % pvalue
    sig.pvalue = 2*(1-normcdf(abs(sig_mat)));
    
    % sort samples in std way
    sig = sort_samples(sig);

    % store ranks
    sig.rank = rankorder(sig_mat, 'direc', 'descend', 'fixties', false);
    
    %% Signal strength and permutation

    % composites in LM space
    lmsig = gctextract_tool(sig, 'ridx', lmidx);
    % instances in LM space
    lmds = gctextract_tool(ds,'ridx',lmidx);
    % signal strength using 100 top/bottom landmarks
    ss = sig_strength(lmsig.mat, 'n', args.ssn);
    % signal strength using number of modulated landmarks
    nsample = ds_get_meta(sig, 'column', 'distil_nsample');
    zs_adj = mortar.compute.SigStrength.adjustZscore(lmsig.mat,nsample);
    ss_ngene = mortar.compute.SigStrength.ssNgene(zs_adj, nsample, ...
        'cutoff', args.ss_ngene_cutoff);
    % TAS using ss_ngene, cc_q75, ones to stop from adjusting scores
    tas = mortar.compute.SigStrength.tas_ngene(ss_ngene,col_cc_q75,1,true);
    tas = [tas.tas_gmean]';
    tas(nsample==1) = -666;
    % permutation stats
    nrep = round(median(nsample));
    [perm_stat, perm_zs] = permute_zs(lmds, nrep,...
        'niter', 1000,...
        'ssn', args.ssn,...
        'clip_low_wt', args.clip_low_wt,...
        'clip_low_cc', args.clip_low_cc,...
        'metric', 'avgz',...
        'modz_metric', args.modz_metric);

    unique_perm_zs_cid = unique(perm_zs.cid);
    fprintf('unique cid created in perm_zs - unique_perm_zs_cid:  %i\n', length(unique_perm_zs_cid))

    % adding metadata fields to sig
    sig = ds_add_meta(sig, 'column', {'distil_ss', 'distil_ss_ngene', ...
        'distil_tas' 'distil_ss_cutoff' 'distil_cc_cutoff'}, ...
        num2cell([ss, ss_ngene, tas, ones(ng,1)*perm_stat.ss_cutoff, ...
        ones(ng,1)*perm_stat.cc_cutoff]));
    % Add provenance code
    if any(strcmp(sig.chd, 'provenance_code'))
        tag = ds_get_meta(sig, 'column', 'provenance_code');
    else
        tag = cell(ng, 1);
    end        
    tag = get_process_code(tag, 'distil', args.metric);
    tag = get_process_code(tag, 'brew', args.group_by);
    sig = ds_add_meta(sig, 'column', 'provenance_code', tag);
    
    % Save results
    if ~isempty(args.out)
        pref = sprintf('%s_COMPZ.%s', args.name, upper(args.metric));
   
        x = sig;
        % SCORE, GCT
        gct_writer(fullfile(args.out, sprintf('%s_SCORE.gct', pref)), x);
        lmds = gctextract_tool(x, 'ridx', find(islmark));
        gct_writer(fullfile(args.out, sprintf('%s_SCORE_LM.gct', pref)), lmds);
        
        % RANK, GCT
        x.mat = x.rank;
        gct_writer(fullfile(args.out, sprintf('%s_RANK.gct', pref)), x, 'precision', 0);
        
        % Genesets, GMT
        sigpref = sprintf('%s_SIG.%s', args.name, upper(args.metric));
        ngene_full = 100;
        ngene_lm = 50;
        % Full feature space, Top 100 features
        [up, dn] =  get_genesets(sig, ngene_full, 'descend');
        mkgmt(fullfile(args.out, sprintf('%s_UP_n%dx%d.gmt', sigpref, ng, ngene_full)), up);
        mkgmt(fullfile(args.out, sprintf('%s_DN_n%dx%d.gmt', sigpref, ng, ngene_full)), dn);
        
        % Landmark space, Top 50 features
        [up_lm, dn_lm] =  get_genesets(lmds, ngene_lm, 'descend');
        mkgmt(fullfile(args.out, sprintf('%s_UP_LM_n%dx%d.gmt', sigpref, ng, ngene_lm)), up_lm);
        mkgmt(fullfile(args.out, sprintf('%s_DN_LM_n%dx%d.gmt', sigpref, ng, ngene_lm)), dn_lm);
        
        % Permutation scores
        gct_writer(fullfile(args.out, sprintf('%s_PERMZS.gct', pref)), perm_zs);
    end
end
end
