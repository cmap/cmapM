function sig_gen(dsfile, varargin)
% SIG_GEN Generate ranked lists.

if isfileexist(dsfile)
    
    pnames = {'out', 'name', 'ngene',...
        'max_zs', 'sig_type', 'group_var',...
        'del_affx_ctl','use_gctx'};
    dflts = {'', '', 100,...
        10, 'stoufz', 'pert_id',...
        false, true};
    args = parse_args(pnames, dflts, varargin{:});
    [~,f, ext] =  fileparts(dsfile);
    if isempty(args.name)        
        args.name = regexprep(f, '_n[0-9]*x[0-9]*$','');
    end
    
    if args.use_gctx
        gct_writer = @mkgctx;
    else
        gct_writer = @mkgct;
    end
    
    % output to folder containing dsfile
    if isempty(args.out) && isfileexist(dsfile)
        args.out = fileparts(dsfile);
    end
    
    switch(ext)
        case {'.gct', '.gctx'}
            ds = parse_gctx(dsfile, 'detect_numeric', false);
        otherwise
            error( 'Unknown file type: %s', dsfile);
    end
    % cutoff for zscore, set to inf to ignore
    % max_zs = 10;
    
    [nf, ns] = size(ds.mat);
    % find lm genes
    allg = ds.rdesc(:, ds.rdict('pr_gene_symbol'));
    %islmark = ~cellfun(@isempty, ds.rdesc(:,
    %ds.rdict('pr_analyte_num')));
%     chip = parse_tbl('/cmap/data/vdb/L1000_EPSILON.chip');
%     islmark = ismember(ds.rid, chip.pr_id);
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
    
    % valid pert_types
    search_type = {'TRT_SH|TRT_SHRNA|TRT_OE|CTL_VECTOR|CTL_VEHICLE|TRT_CP'};
    % unique cell types
    search_cell = unique(ds.cdesc(:,ds.cdict('cell_id')));
    nc = length(search_cell);
    % unique time points
    search_time = unique(ds.cdesc(:, ds.cdict('pert_time')));
    nt = length(search_time);
    
    for c = 1:nc
        for t=1:nt
            [keep_desc, keep_idx] = filter_table(ds.cdesc, ...
                {'pert_type', 'cell_id', 'pert_time'}, ...
                [search_type, search_cell(c), search_time(t)], 'tblhdr', ds.chd);
            prefix = print_dlm_line([search_cell(c), search_time(t)],'dlm', '_'); 
            [~, prefix] = validate_fname(prefix, '_');
            nkeep = length(keep_idx);
            if nkeep>0
                group_id = unique(keep_desc(:, ds.cdict(args.group_var)));                
                ng = length(group_id);
                sig.score = zeros(nfeature, ng);
                sig.cid = cell(ng, 1);
                %additional signature specific fields
                sigfn = unique([ds.chd; {'sig_type'; 'sig_classa'; ...
                    'sig_classb';'sig_na';'sig_nb';'islmark';'sig_classa_wt'}]);
                sigann = cell(ng, length(sigfn));
                sigdict = containers.Map(sigfn, 1:length(sigfn));
                for g = 1:ng
                    %exact match for each group_id
                    [sig_desc, sig_idx] = filter_table(keep_desc, ...
                        {args.group_var}, group_id(g), 'tblhdr', ds.chd,...
                        'matchtype', 'exact');
                    pert_desc = unique(sig_desc(:,ds.cdict('pert_desc')));
                    sig.cid{g} =  sprintf('%s:%s:%s:%s', group_id{g}, pert_desc{1}, search_cell{c}, search_time{t});
                   
                    % sample index in ds
                    samp_idx = keep_idx(sig_idx);
                    zs = ds.mat(feature_idx, samp_idx);
                    if ~isinf(args.max_zs)
                        zs = clip(zs, -args.max_zs, args.max_zs);
                    end
                    switch (lower(args.sig_type))
                        case 'stoufz'
                            % Stouffer's Zscore
                            sig.score(:, g) = sum(zs, 2)/sqrt(length(samp_idx));
                            samp_wt = ones(size(samp_idx));
                        case 'medz'
                            %median
                            sig.score(:, g) = median(zs, 2);
                            samp_wt = ones(size(samp_idx));
                        case 'modz'
                            % zs moderated by replicate correlations
                            [sig.score(:, g), samp_wt] = modzs(zs, lmidx);
                        otherwise
                            error('Unknown signature method: %s', args.sig_type)
                    end
                    
                    %signature annotations
                    sigann{g, sigdict('sig_type')} = lower(args.sig_type);
                    sigann{g, sigdict('sig_classa')} = ...
                        print_dlm_line(ds.cid(samp_idx), 'dlm', '|');
                    sigann{g, sigdict('sig_classa_wt')} = ...
                        print_dlm_line(samp_wt, 'dlm', ',', 'precision', 4);
                    sigann{g, sigdict('sig_classb')} = '-666';
                    sigann{g, sigdict('sig_na')} = length(sig_idx);
                    sigann{g, sigdict('sig_nb')} = 0;
                    sigann{g, sigdict('islmark')} = max(ismember(pert_desc, lmgene));
                    % add merged fields of existing annotations
                    for ii=1:length(ds.chd)
                        ann = ds.cdesc(samp_idx, ds.cdict(ds.chd{ii}));
                        uniqann = unique(ann);
                        if length(uniqann)>1
                            sigann{g, sigdict(ds.chd{ii})} = print_dlm_line(ann, 'dlm', '|', 'precision', 1);
                        else
                            sigann(g, sigdict(ds.chd{ii})) = uniqann;
                        end
                    end
                    fprintf('%s islmark:%d numrep:%d\n', sig.cid{g}, sigann{g, sigdict('islmark')}, length(samp_idx))
                end
                % pvalue
                sig.pvalue = 2*(1-normcdf(abs(sig.score)));
                %     % Adjusted pvalue, Bonferroni-Holm
                %     sig.padjust = zeros(size(sig.pvalue));
                %     for ii=1:ng
                %         sig.padjust(:,ii) = padjust(sig.pvalue(:,ii));
                %     end
                sig.rank = rankorder(sig.score, 'direc', 'descend', 'fixties', false);
                
                sig.cdict = sigdict;
                sig.chd = sigfn;
                sig.cdesc = sigann;
                sig.rid = ds.rid(feature_idx);
                sig.rhd = ds.rhd;
                sig.rdesc = ds.rdesc(feature_idx,:);

                %save results
                % all in one mat
                pref = sprintf('%s_%s_SIG.%s', args.name, prefix, upper(args.sig_type));
%                 save(fullfile(args.out, sprintf('%s_n%dx%d.mat', pref, ng, nfeature)), 'sig');
                x=sig;
                % RANK
                x.mat = x.rank;
                gct_writer(fullfile(args.out, sprintf('%s_RANK.gct', pref)), x,'precision',0);
                % SCORE
                x.mat = x.score;
                gct_writer(fullfile(args.out, sprintf('%s_SCORE.gct', pref)), x);
                % Genesets, GMT
                [~, srtidx]=sort(sig.score,'descend');
                up = cell(ng,1);
                dn = cell(ng,1);
                for ii=1:ng
                    up{ii} = sig.rid(srtidx(1:args.ngene, ii));
                    dn{ii} = sig.rid(srtidx(end-(0:args.ngene-1), ii));
                end
                uphd = strcat(sig.cid,'_UP');
                dnhd = strcat(sig.cid,'_DN');
                desc = strcat('type:', sig.cdesc(:, sig.cdict('pert_type')));
                desc = strcat(desc, ' n:', num2cellstr(cell2mat(sig.cdesc(:, sig.cdict('sig_na')))));
                desc = strcat(desc, ' lmark:', num2cellstr(cell2mat(sig.cdesc(:, sig.cdict('islmark')))));                
                mkgmt(fullfile(args.out, sprintf('%s_UP_n%dx%d.gmt', pref, ng, args.ngene)), up, uphd, desc);
                mkgmt(fullfile(args.out, sprintf('%s_DN_n%dx%d.gmt', pref, ng, args.ngene)), dn, dnhd, desc);
            end
        end
    end
    

else
    error('File not found: %s', dsfile);
end
