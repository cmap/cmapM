function combods = liss_pipe( varargin )
% LISS_PIPE Normalize Luminex expression data using invariant set scaling

toolname = mfilename;
fprintf('-[ %s ]- Start\n', upper(toolname));
% parse args
pnames = {'plate', 'overwrite',...
    'debug', 'rpt', 'log2', ...
    'fitmodel', 'precision', 'minval',...
    'maxval', 'mkcalplot', 'lowmem',...
    'censor_bad', 'plate_path', 'verify'};
dflts =  {'', true, ...
    false,    toolname, true, ...
    'power', 4, 0, ...
    15, true, false, ...
    true, '.', false};

arg = parse_args(pnames, dflts,varargin{:});            
print_args(toolname, 1, arg);
if ~isempty(regexp(arg.plate,'.grp$', 'once'))
    plates = parse_grp(arg.plate);
else
    plates = {arg.plate};
end
nplate = length(plates);

start_time = tic;

for pn=1:nplate
    % get plate info
    plateinfo = parse_platename(plates{pn}, arg);    
    % check if NORM file exists
    d = dir(fullfile(plateinfo.plate_path, sprintf('%s_NORM_*.gct',...
        plateinfo.plate)));
    normexists = ~isempty(d);
    % Dataset(s)
    dspath = fullfile(plateinfo.plate_path,'dpeak');
    d = dir(fullfile(dspath, sprintf('*_GEX_*.gct')));
    ds = {d.name}';

    nds = length(ds);
    if isequal(nds, length(plateinfo.bset))
        rawgctexists = true;
    else
        rawgctexists = false;
    end
    if ~arg.overwrite && normexists
        fprintf('%s: NORM dataset exists, skipping...\n', plateinfo.plate);
    elseif rawgctexists
        % lockfile = fullfile(plateinfo.plate_path,sprintf('%s.lock',plateinfo.plate));
        % if lock(lockfile)
        fprintf('%s: Processing...\n', plateinfo.plate);
        % reference calib values
        if isfileexist(plateinfo.yref)
            yref = parse_gct(plateinfo.yref, 'class', 'double');
        else
            error (toolname, '%s not found', arg.yref);
        end
        
        tstart=tic;
        if nds > 0
            fprintf ('Found %d dataset(s) to normalize\n', nds);
            % analysis ouput folders
            wkdir = mkworkfolder(plateinfo.plate_path, 'liss', ...
                'forcesuffix', false, 'overwrite', true);
            % path for figures
            figdir = mkworkfolder(wkdir, 'figures',...
                'forcesuffix', false, 'overwrite', true);
            
            fprintf ('Saving analysis to %s\n',wkdir);
            fid = fopen(fullfile(wkdir, sprintf('%s_params.txt',...
                toolname)), 'wt');
            print_args(arg.rpt, fid, arg);
            fclose (fid);
%                 sc = mkgctstruct;
            avg_slope = 0;
            avg_flogp = 0;
            avg_iqr = 0;
            qc_failidx = [];
            for ii=1:nds
                % parse ds
                fprintf ('%d/%d Parsing %s\n', ii, nds, ds{ii});
                raw = parse_gct(fullfile(dspath, ds{ii}), 'class',...
                    'double');
                % transform
                fprintf ('Log2 transforming\n');
                raw.mat = safe_log2(raw.mat);
                % get calib matrix
                calib = ...
                    gen_calib_matrix(strrep(plateinfo.invset,'_analyte',...
                    '_cal'), raw);                   
                % Perform normalization
                if ~isempty(raw.cid)
                    fprintf ('Performing normalization...\n');
                    [sc(ii), qcrpt, cal, failidx] = liss(raw, calib,...
                        yref.mat, arg);
                    % column indices that failed
                    qc_failidx = union(qc_failidx, failidx);
                    % append quality scores
                    % Calib slope in degrees
                    qc_slope = zeros(size(qcrpt));
                    qcpass = [qcrpt.qcpass]>0;
                    qc_slope(qcpass) = [qcrpt(qcpass).calib_slope_deg];
                    qc_slope_str = num2cellstr(qc_slope(:),...
                        'precision', 0);
                    avg_slope = avg_slope + qc_slope(:);
                    
                    % F statistic
                    qc_flogp = zeros(size(qcrpt));
                    qc_flogp(qcpass) = [qcrpt(qcpass).f_logpval];
                    qc_flogp_str = num2cellstr(qc_flogp(:), 'precision', 1);
                    avg_flogp = avg_flogp + qc_flogp(:);
                    
                    %Sample IQR
                    qc_iqr = zeros(size(qcrpt));
                    qc_iqr(qcpass) = [qcrpt(qcpass).iqr];
                    qc_iqr_str = num2cellstr(qc_iqr(:), 'precision', 2);
                    avg_iqr = avg_iqr + qc_iqr(:);
                    annot = struct('id', sc(ii).cid,...
                        'qc_slope', qc_slope_str,...
                        'qc_f_logp', qc_flogp_str,...
                        'qc_iqr', qc_iqr_str);
                    
                    % add metadata w/o calling annotate_ds
                    sc(ii) = l1kt_annotate_ds(sc(ii), annot, 'column');
                    
                    % sc(ii) = annotate_ds(sc(ii), annot, 'dim', 'column');
                    % add process code
                    % sc(ii) = update_provenance(sc(ii), 'liss', 'invariant_norm');
                    
                    [p, dsname, e] = fileparts(ds{ii});
                    save_liss(sc(ii), qcrpt, cal, sc(ii).cid(failidx), arg,...
                        dsname, wkdir);
                else
                    fprintf ('No samples to normalize!..skipping');
                end
            end
            
            % combined NORM dataset
            combods = combinegct(sc, 'keepshared', false);
            % use profile names
            welldict = map_samples(plateinfo.local_map, plateinfo, varargin{:});
            wn = get_wellinfo(combods.cid);
            pvals = welldict.values(wn);
            combods.cid = cellfun(@(x) x.prof_name, pvals,...
                'uniformoutput', false);
            %update quality scores
            avg_flogp = avg_flogp/nds;
            avg_iqr = avg_iqr/nds;
            avg_slope = avg_slope/nds;
            annot = struct( 'id', combods.cid,...
                'qc_slope', num2cellstr(avg_slope, 'precision', 0),...
                'qc_f_logp', num2cellstr(avg_flogp, 'precision', 1),...
                'qc_iqr', num2cellstr(avg_iqr, 'precision', 2));
            % combods = annotate_ds(combods, annot, 'dim', 'column');

            % add metadata w/o calling annotate_ds
            combods = l1kt_annotate_ds(combods, annot, 'column');
            
            % censor bad samples                
            good = true(length(combods.cid), 1); 
            if arg.censor_bad
                if ~isempty(qc_failidx)
                    good(qc_failidx) = false;
                end
                try
                    %load qc stats
                    qcstats = load_qcstats(plateinfo.plate_path, plateinfo);
                    mustats = avg_stats(qcstats);
                    bad_idx = bad_samples(mustats);
                    good(bad_idx) = false;
                catch e
                    disp(e)
                    warning('qnorm_pipe:QCNotFound', ...
                        'Error loading QC stats file, using IQR and counts instead');
                    mustats.sample = combods.cid;
                    mustats.iqr = pow2(iqr(combods.mat));
                    bad_idx = bad_samples(mustats, ...
                        'metric', {'iqr'}, 'minval', 2,...
                        'tail', {'both'});
                    good(bad_idx) = false;
                end
                
                % wells with bad count stats
                % ensure these are numeric types
                count_cv = cell2mat(combods.cdesc(:, combods.cdict('count_cv')));
                count_mean = cell2mat(combods.cdesc(:, combods.cdict('count_mean')));
                bad_count = union(find(count_mean < 20 & count_cv > 30),...
                    intersect(outlier1d(count_mean, 'cutoff', 2, 'tail', 'left'),...
                    outlier1d(count_cv, 'cutoff', 2, 'tail', 'right')));                    
                good(bad_count) = false;

                % also remove process controls
                lma_ctl = find(strncmpi('LMA_', ...
                    combods.cdesc(:, combods.cdict('pert_type')), 4));
                good(lma_ctl) = false;
            end
            noutlier = nnz(~good);
                            
            % discard censored samples
            % outlier ds
            keep_field={'det_well';...
                'cell_id';...
                'pert_id';...
                'pert_mfc_desc';...
                'pert_type';...
                'count_mean';...
                'count_cv';...
                'qc_f_logp';...
                'qc_iqr';...
                'qc_slope'};
            if noutlier
                
                fprintf ('%d samples removed (%d outliers, %d process controls).\n', ...
                    noutlier, noutlier-length(lma_ctl), length(lma_ctl));

                outds = gctextract_tool(combods, 'cid', combods.cid(~good));
                keep_field = keep_field(outds.cdict.isKey(keep_field));
                fnidx = cell2mat(outds.cdict.values(keep_field));
                outrpt = [outds.cid, outds.cdesc(:, fnidx)];
                
                % remove outliers
                keepcid = combods.cid(good);
                combods = gctextract_tool(combods, 'cid', keepcid);
                
                % outlier report
                mktbl(fullfile(wkdir, 'outlier_samples.txt'), ...
                    outrpt, 'header', ['id'; keep_field], ...
                    'precision', 2);
                
                % save outlier data
                mkgct(fullfile(wkdir, 'outlier.gct'), outds);
                
            else
                % create an empty outlier report
                mkgrp(fullfile(wkdir, 'outlier_samples.txt'), ...
                    {print_dlm_line(['id'; keep_field])});                    
            end
            
            mkgct(fullfile(plateinfo.plate_path, sprintf('%s_NORM.gct',...
                plateinfo.plate)), combods, 'precision', arg.precision);
            
            %POST LISS Plots
            % post_liss_figures(plateinfo.plate_path, 'figdir', figdir);
        else
            error ('No valid datasets not found: %s', arg.res);
        end
        fprintf ('Saved data to:%s\nEND %s %4.0f secs\n', wkdir,...
            arg.rpt, toc(tstart));
        %     unlock(lockfile);
        % else
        %     fprintf('%s: locked, skipping...\n', plateinfo.plate);
        % end
    else
        fprintf ('%s: no raw gct files found, skipping\n', plateinfo.plate);
    end
end

fprintf('-[ %s ]- Done. (%2.2fs)\n', upper(toolname), toc(start_time));
end
%% save results
function save_liss(sc, qcrpt, cal, cid_fail, arg, dsname, wkdir)
[numFeatures, numSamples] = size(sc.mat);
totLevels = size(cal.mat, 1);

% calib curve, observed
fname = fullfile(wkdir, sprintf('calib_%s_n%dx%d.gct', dsname,...
    numSamples, totLevels-2));
mkgct(fname, cal, 'appenddim', false, 'precision', arg.precision);
% calibplot
plot_calib(cal.mat(:,2:11)', 'showfig', false,...
            'islog2', true, 'showsamples', true, 'title', ...
            sprintf('Calibration plot n=%d',size(cal.mat,1)));
namefig('calibplot');
savefigures('out', fullfile(wkdir,'..'), 'mkdir', false,...
            'closefig', true, 'overwrite', true);

% % calib curve, fit
% fname = fullfile(wkdir, sprintf('calib_postnorm_n%dx%d.gct',numSamples, totLevels-2));
% mkgct0(fname, cal_fit, sc.cid, desc, levelLabels(1:end-2), arg.precision);

% normalized data matrix
fname_sc = fullfile(wkdir, sprintf('%s_liss%s.gct', dsname,...
    arg.fitmodel(1)));
mkgct(fname_sc, sc, 'appenddim', false, 'precision', arg.precision);

% samplewise fit report
fname_fitrpt = fullfile(wkdir, sprintf('stats_%s_%s.txt', arg.fitmodel,...
    dsname));
mktbl(fname_fitrpt, qcrpt, 'emptyval', 'nan');

% report qcfails
if ~isempty(cid_fail)
    fid = fopen(fullfile(wkdir, sprintf('qcfail_%s.txt', dsname)), 'wt');
    print_dlm_line(cid_fail, 'fid', fid, 'dlm', '\n');
    fclose(fid);
end
end


