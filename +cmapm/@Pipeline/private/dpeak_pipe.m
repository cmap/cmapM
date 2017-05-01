function dpeak_pipe(varargin)
% DPEAK_PIPE Generate GEX datasets for L1000 pipeline.

toolname = mfilename;
fprintf('-[ %s ]- Start\n', upper(toolname));
% startup_defaults;
pnames = {'plate', 'overwrite', 'precision', ...
    'flipcorrect', 'parallel', 'randomize',...
    'use_smdesc', 'lxbhist_analyte', 'lxbhist_well',...
    'detect_param', 'setrnd', 'rndseed', ...
    'incomplete_map', 'plate_path'};
dflts = { '', false, 1, ...
    true, true, true, ...
    false, '25,182,286,373,463', 'A05,N13,G17',...
    fullfile(cmapmpath,'resources', 'detect_params.txt'), true, '', ...
    false, '.'};
arg = parse_args(pnames, dflts, varargin{:});

if ~isempty(regexp(arg.plate,'.grp$', 'once'))
    plates = parse_grp(arg.plate);
    if arg.randomize
        plates = plates(randperm(length(plates)));
    end
else
    plates = {arg.plate};
end
nplate = length(plates);

start_time = tic;
for p = 1:nplate
    % get plate info
    plateinfo = parse_platename(plates{p},varargin{:});
    % check if dpeak pkstats file exists
    if strcmpi(plateinfo.detmode, 'DUO')
        d = dir(fullfile(plateinfo.plate_path,sprintf('dpeak/%s*.mat',plateinfo.plate)));
        pkexists = ~isempty(d);
    elseif strcmpi(plateinfo.detmode, 'UNI')
        d = dir(fullfile(plateinfo.plate_path,'dpeak/*GEX*.gct'));
        pkexists = isequal(length(d), 2);
    else
        d = dir(fullfile(plateinfo.plate_path,'dpeak/*GEX*.gct'));
        pkexists = ~isempty(d);
    end
    
    if ~arg.overwrite && pkexists
        fprintf('%s: dpeak output file exists, skipping...\n', plateinfo.plate);
    else
        % lockfile = fullfile(plateinfo.plate_path,sprintf('%s.lock',plateinfo.plate));
        % if lock(lockfile)
        %% analysis ouput folders
        wkdir = mkworkfolder(plateinfo.plate_path, 'dpeak', 'forcesuffix', false, 'overwrite', true);
        fprintf ('Saving analysis to %s\n',wkdir);
        % path for figures
        figdir = mkworkfolder(wkdir, 'figures', 'forcesuffix', false, 'overwrite', true);
        % sample map
        [welldict, wpairs] = map_samples(plateinfo.local_map, plateinfo, 'use_smdesc', arg.use_smdesc, varargin{:});
        % feature map
        fmap = parse_tbl(plateinfo.chip, 'outfmt', 'record');
        % Detection parameters
        detect_param = parse_param(arg.detect_param);
        
        switch plateinfo.detmode
            case 'uni'
                % assume one pool, two bsets
                % load csv datasets
                ds = parse_csv(plateinfo.csv_path);
                % set min to 1, discard NaNs
                ds.mat = max(ds.mat, 1);
                %Bead count info
                dscnt = parse_csv(plateinfo.csv_path, 'type', 'Count');
                
                % get well annotations and extract wells if incomplete map file
                ds = annotate_wells(ds, plateinfo, varargin{:});
                dscnt = annotate_wells(dscnt, plateinfo, varargin{:});
                [nGene, nSample] = size(ds.mat);
                [wells,word] = get_wellinfo(ds.cid);
                
                %add bead count stats
                stats = uni_count_stats(wells, dscnt, wpairs);
                meta_hd = {'count_mean', 'count_cv'};
                meta = [num2cellstr(stats.min_count, 'precision', 0),...
                    num2cellstr(stats.max_cv, 'precision', 0)];
                ds = ds_add_meta(ds, 'column', meta_hd, meta);
                % add process code
                ds = update_provenance(ds, 'dpeak', 'uni');
                nbset = length(plateinfo.bset);
                bsetds = mkgctstruct();
                %counts
                bsetcnt = mkgctstruct();
                nprof = length(wpairs);
                % bead set data
                for ii=1:nbset
                    % wells of current bset
                    wbset = cellfun(@(x)x{ii}, wpairs, 'uniformoutput', false);
                    [wcmn, widx] = intersect_ord(ds.well, wbset);
                    if ~isequal(length(wcmn), nSample/2)
                        error('Some samples could not be mapped');
                    end
                    % features
                    [this_rid, this_rhd, this_rdesc, ridx] = ...
                        map_features(fmap, ds.rid, ...
                        welldict(wells{1}).pool, plateinfo.bset{ii},...
                        'bset_revision', plateinfo.bset_revision, ...
                        varargin{:});
                    bsetds(ii) = mkgctstruct(ds.mat(ridx, widx),...
                        'rid', this_rid, 'rhd', this_rhd, 'rdesc', this_rdesc,...
                        'cid', ds.cid(widx), 'chd', ds.chd, 'cdesc', ds.cdesc(widx,:));
                    
                    %counts
                    bsetcnt(ii) = mkgctstruct(dscnt.mat(ridx, widx),...
                        'rid', this_rid, 'rhd', this_rhd, 'rdesc', this_rdesc,...
                        'cid', ds.cid(widx), 'chd', ds.chd, 'cdesc', ds.cdesc(widx,:));
                    % create bset gcts
                    mkgct(fullfile(wkdir, sprintf('%s_GEX.gct', plateinfo.bset{ii})), bsetds(ii),'precision',1)
                end
                % create GEX file
                combods = combinegct(bsetds,'keepshared',false);
                combo_count = combinegct(bsetcnt,'keepshared',false);
                
                %use profile names
                pvals = welldict.values(get_wellinfo(bsetds(1).cid));
                combods.cid = cellfun(@(x) x.prof_name, pvals, 'uniformoutput', false);
                combo_count.cid = combods.cid;
                mkgct(fullfile(plateinfo.plate_path, sprintf('%s_GEX.gct', plateinfo.plate)), combods, 'precision', 1)
                mkgct(fullfile(plateinfo.plate_path, sprintf('%s_COUNT.gct', plateinfo.plate)), combo_count, 'precision', 0)
                
                % Viability stats
                qcode = bsetcnt(1);
                qcode.mat = min(bsetcnt(1).mat ,bsetcnt(2).mat) > detect_param.min_bead;
                mkgct(fullfile(wkdir, sprintf('%s_QCODE.gct', plateinfo.bset{ii})), ...
                    qcode, 'precision', 0)
                hf = plot_qcode_stats(qcode.mat, 'showfig', false);
                savefigures('out', fullfile(wkdir, 'figures'),...
                    'mkdir', false, ...
                    'overwrite', true,...
                    'closefig', true)
            case 'duo'
                tic
                % background correction
                if detect_param.subtract_bg
                    d = dir(fullfile(plateinfo.raw_path, '*.lxb'));
                    wn = unique(get_wellinfo({d.name}'));
                    %estimate bkg by sampling 10 random wells
                    bgwells = wn(randsample(1:length(wn), 10));
                    [bkg, bkg_correct] = estimate_bkg(plateinfo.raw_path, bgwells);
                else
                    bkg_correct = 0;
                end
                % detect peaks
                [pkstats, fn] = detect_lxb_peaks_folder(plateinfo.raw_path, ...
                    'lowthresh', detect_param.low_exp, ...
                    'highthresh', detect_param.high_exp, ...
                    'pkmethod', detect_param.dpeak_method, ...
                    'max_k', detect_param.max_k, ...
                    'minbead', detect_param.min_bead, ...
                    'min_peak_support', detect_param.min_peak_support, ...
                    'min_peak_support_pct', detect_param.min_peak_support_pct, ...
                    'opt_support_pct', [detect_param.opt_support_pct_hi, detect_param.opt_support_pct_lo], ...
                    'parallel', arg.parallel, ...
                    'notduo', plateinfo.notduo, ...
                    'out', wkdir, ...
                    'subtractbg', detect_param.subtract_bg, ...
                    'merge_close_peaks', detect_param.merge_close_peaks, ...
                    'setrnd', arg.setrnd, ...
                    'rndseed', arg.rndseed, ...
                    'include_well', welldict.keys);
                fprintf ('%s processed in %f secs\n', plateinfo.plate, toc);
                %save pkstats
                save(fullfile(wkdir, [plateinfo.plate, '.mat']), 'pkstats');
                [nanalyte, nwells] = size(pkstats);
                % bead counts
                mean_count = zeros(nwells, 1);
                cv_count = zeros(nwells, 1);
                for ii=1:size(pkstats, 2)
                    cnt = [pkstats(11:end,ii).ngoodbead];
                    mean_count(ii) = mean(cnt);
                    cv_count(ii) = 100 * std(cnt) / mean_count(ii);
                end
                
                % dummy dataset to get annotated well info
                wells = get_wellinfo(fn);
                rid = gen_labels(nanalyte, 'prefix', 'Analyte ', 'zeropad', false);
                ds = mkgctstruct(zeros(nanalyte, nwells), 'rid', rid, 'cid', wells);
                ds = annotate_wells(ds, plateinfo, varargin{:});
                % add bead count stats
                meta_hd = {'count_mean', 'count_cv'};
                meta = [num2cellstr(mean_count, 'precision', 0),...
                    num2cellstr(cv_count, 'precision', 0)];
                ds = ds_add_meta(ds, 'column', meta_hd, meta);
                % add process code
                % ds = update_provenance(ds, 'dpeak', detect_param.dpeak_method);
                
                % assign peaks
                assign = assign_lxb_peaks(pkstats,...
                    'min_support', detect_param.min_peak_support,...
                    'min_support_pct', detect_param.min_peak_support_pct,...
                    'out', wkdir);
                
                % bead set data
                for ii=1:length(plateinfo.bset)
                    % map features
                    [this_rid, this_rhd, this_rdesc, ridx] = map_features(...
                        fmap, rid, welldict(wells{1}).pool, ...
                        plateinfo.bset{ii}, ...
                        'bset_revision', plateinfo.bset_revision,...
                        varargin{:});
                    bsetds(ii) = mkgctstruct(assign(ii).mat, ...
                        'rid', this_rid, 'rhd', this_rhd, 'rdesc', this_rdesc,...
                        'cid', ds.cid, 'chd', ds.chd, 'cdesc', ds.cdesc);
                    
                    % create bset gcts
                    mkgct(fullfile(wkdir, ...
                        sprintf('%s_RAW.gct', plateinfo.bset{ii})),...
                        bsetds(ii), 'precision', arg.precision);
                    
                    %counts
                    bsetcnt(ii) = mkgctstruct(assign(ii).support, ...
                        'rid', this_rid, 'rhd', this_rhd, 'rdesc', this_rdesc,...
                        'cid', ds.cid, 'chd', ds.chd, 'cdesc', ds.cdesc);
                    mkgct(fullfile(wkdir, ...
                        sprintf('%s_COUNT.gct', plateinfo.bset{ii})),...
                        bsetcnt(ii), 'precision', arg.precision);
                    
                    %pct support
                    bsetpct(ii) = mkgctstruct(assign(ii).support_pct, ...
                        'rid', this_rid, 'rhd', this_rhd, 'rdesc', this_rdesc,...
                        'cid', ds.cid, 'chd', ds.chd, 'cdesc', ds.cdesc);
                    mkgct(fullfile(wkdir, ...
                        sprintf('%s_PCTCOUNT.gct', plateinfo.bset{ii})),...
                        bsetpct(ii), 'precision', arg.precision);
                end
                
                % counts
                combo_count = combinegct(bsetcnt, 'keepshared', false);
                % use profile names
                combo_count.cid = ds.profname;
                mkgct(fullfile(plateinfo.plate_path,...
                    sprintf('%s_COUNT.gct', plateinfo.plate)), ...
                    combo_count, 'precision', 0)
                
                % Save Peak viability stats
                nviable = get_peak_viability(pkstats, ...
                    detect_param.min_peak_support, ...
                    detect_param.min_peak_support_pct);
                
                viable = mkgctstruct(nviable, ...
                    'rid', rid, ...
                    'cid', ds.profname,...
                    'cdesc', ds.cdesc,...
                    'chd', ds.chd);
                
                mkgct(fullfile(wkdir, ...
                    sprintf('viability.gct')),...
                    viable, 'precision', 0);
                
            otherwise
                error('Unknown detmode: %s', plateinfo.detmode)
        end
    end
end
fprintf('-[ %s ]- Done. (%2.2fs)\n', upper(toolname), toc(start_time));
end

