function [sig, perm_zs, perm_stat, perm_cutoff] = distil(ds, varargin)
% DISTIL Generate composite deltas.

%TOFIX: only accepts datasets parsed with 'detect_numeric' set to false.

pnames = {'out', 'name', ...
    'clip_range', 'metric', 'group_by',...
    'del_affx_ctl','use_gctx', 'debug',...
    'clip_low_wt','cid_prefix','modz_metric',...
    'ssn', 'clip_low_cc', 'pert_desc_field',...
    'cid'};
dflts = {'', '', ...
    [-10, 10], 'modz', 'cell_id,pert_time,pert_id',...
    false, true, true,...
    true, '', 'wt_avg',...
    100, true, 'pert_mfc_desc',...
    ''};
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
    dbg(args.debug, 'Clipping scores to [%2f, %2f]',args.clip_range(1), args.clip_range(2));
    ds.mat = clip(ds.mat, args.clip_range(1), args.clip_range(2));
end
nf = size(ds.mat);
% find lm genes
allg = ds.rdesc(:, ds.rdict('pr_gene_symbol'));
islmark = islandmark(ds.rid, unique(ds.cdesc(:, ds.cdict('pool_id'))));
% need indices for modzs
lmidx = find(islmark);
lmgene = unique(allg(islmark));

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
search_cell = unique(ds.cdesc(:,ds.cdict('cell_id')));
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
    sig.mat = zeros(nfeature, ng);
    sig.cid = cell(ng, 1);
    %additional signature specific fields
    new_fields = {'distil_metric';...
        'distil_id'; ...
        'distil_wt';...
        'distil_cc_max';...
        'distil_cc_median';...
        'distil_cc_q75';...
        'distil_ss';...
        'distil_ss_cutoff';...
        'distil_cc_cutoff';...
        'distil_nsample';...
        'islmark'};
    sigfn = unique([ds.chd; new_fields]);
    sigann = cell(ng, length(sigfn));
    sigdict = containers.Map(sigfn, 1:length(sigfn));
    for g = 1:ng
        % Exact match for each group_id
        sig_idx = find(group_idx==g);
        sig_desc = keep_desc(sig_idx, :);

        pert_desc = unique(sig_desc(:,ds.cdict(args.pert_desc_field)));
        if isempty(args.cid_prefix)
            sig.cid{g} =  print_dlm_line(upper(group_id(g)), 'dlm', ':');
        else
            sig.cid{g} = print_dlm_line(upper({args.cid_prefix, group_id{g}}), 'dlm', ':');
        end
        % fix for spaces
        sig.cid{g} = regexprep(sig.cid{g},' +','_');
        % sample index in ds
        samp_idx = keep_idx(sig_idx);
        zs = ds.mat(feature_idx, samp_idx);
        [sig.mat(:, g), samp_wt, cc] = distil_core(zs, lower(args.metric), ...
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
            print_dlm_line(cc_q75, 'dlm', ',', 'precision', 2);
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
        dbg(args.debug, '%s islmark:%d numrep:%d', sig.cid{g}, sigann{g, sigdict('islmark')}, length(samp_idx))
    end
    % pvalue
    sig.pvalue = 2*(1-normcdf(abs(sig.mat)));
    
    sig.cdict = sigdict;
    sig.chd = sigfn;
    sig.cdesc = sigann;
    sig.rid = ds.rid(feature_idx);
    sig.rhd = ds.rhd;
    sig.rdesc = ds.rdesc(feature_idx,:);
    % sort samples in std way
    sig = sort_samples(sig);
    % store ranks
    sig.rank = rankorder(sig.mat, 'direc', 'descend', 'fixties', false);
    
    %% Signal strength and permutation
    % composites in LM space
    lmsig = gctextract_tool(sig, 'ridx', lmidx);
    % instances in LM space
    lmds = gctextract_tool(ds,'ridx',lmidx);
    % signal strength using 100 top/bottom landmarks
    ss = sig_strength(lmsig.mat, 'n', args.ssn);
    % permutation stats
    nrep = round(median(cell2mat(sig.cdesc(:, sig.cdict('distil_nsample')))));
    [perm_stat, perm_zs] = permute_zs(lmds, nrep,...
        'niter', 1000,...
        'ssn', args.ssn,...
        'clip_low_wt', args.clip_low_wt,...
        'clip_low_cc', args.clip_low_cc,...
        'metric', 'avgz',...
        'modz_metric', args.modz_metric);
    sig.cdesc(:, sig.cdict('distil_ss')) = num2cell(ss);
    sig.cdesc(:, sig.cdict('distil_ss_cutoff')) = num2cell(perm_stat.ss_cutoff);
    sig.cdesc(:, sig.cdict('distil_cc_cutoff')) = num2cell(perm_stat.cc_cutoff);
    
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
