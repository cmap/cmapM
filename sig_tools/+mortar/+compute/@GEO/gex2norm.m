function [qn,sc] =  gex2norm(varargin)
% GEX2NORM Normalize raw gene expression data.

toolname = mfilename;
fprintf('-[ %s ]- Start\n', upper(toolname));
% parse args
pnames = {'res',...
    'overwrite',...
    'out'...
    'yref', ...
    'invset',...
    'verbose',...
    'rpt',...
    'islog2', ...
    'fitmodel',...
    'precision',...
    'minval',...
    'maxval',...
    'mkcalplot',...
    'lowmem',...
    'censorbad',...
    'showfig',...
    'use_sketch',...
    'target_sketch',...
    'use_gctx',...
    'save_output',...
    'save_matrix'};

dflts =  {'',...
    false,...
    '',...
    fullfile(mortarconfig('l1k_config_path'), 'log_ybio_epsilon.gct'),...
    fullfile(get_l1k_path('spaces_path'), 'inv_eps_n80_probes.gmx'),...
    true,...
    toolname,...
    false, ...
    'power',...
    4,...
    0, ...
    15,...
    true,...
    false,...
    true,...
    false,...
    false,...
    fullfile(mortarconfig('vdb_path'),'sketch/sketch20k_median_n1x22268.gctx'),...
    false,...
    true,...
    true};

args = parse_args(pnames, dflts,varargin{:});            
print_args(toolname, 1, args);

if args.save_output
    pfile = fullfile(args.out, sprintf('%s_params.txt',toolname));
    print_args(toolname, pfile, args);
    
    if isempty(args.out)
        args.out = pwd;
    elseif ~isdirexist(args.out)
        mkdir(args.out)
    end
end
gctwriter = ifelse(args.use_gctx, @mkgctx, @mkgct);

start_time = tic;

if isstruct(args.res) || isfileexist(args.res)
    % invariant set
    if ~isfileexist(args.invset)
        error (toolname, '%s not found', args.invset);
    end
    % reference calib values
    if isfileexist(args.yref)
        yref = parse_gct(args.yref, 'class', 'double');
    else
        error (toolname, '%s not found', args.yref);
    end    
    %load ds
    raw = parse_gctx(args.res, 'class', 'double');
    %transform
    if ~args.islog2
        fprintf ('Log2 transforming...\n')
        raw.mat = safe_log2(raw.mat);
    end
    
    % get calib matrix
    calib = gen_calib_matrix(args.invset, raw);
    if args.save_matrix
        calibfile = fullfile(args.out, 'calib.gct');
        gctwriter(calibfile, calib, 'precision', args.precision);
    end
    % Perform normalization
    if ~isempty(raw.cid)
        dbg(args.verbose, 'Performing invariant-set normalization...');
        [sc, qcrpt, cal, cidx_fail] = liss(raw, calib,...
            yref.mat, args);
        
        % append quality scores
        % Calib rng
        cal_linear=pow2(cal.mat(:,2:end-2)');
        qc_range = max(cal_linear)-min(cal_linear);
        qc_fold_change = max(cal_linear)./min(cal_linear);
        qc_range_str = num2cellstr(qc_range(:),...
            'precision', 0);
        qc_fold_change_str = num2cellstr(qc_fold_change(:),...
            'precision', 1);
        
        % Calib slope in degrees
        qc_slope = zeros(size(qcrpt));
        qcpass = [qcrpt.qcpass]>0;
        qc_slope(qcpass) = [qcrpt(qcpass).calib_slope_deg];
        qc_slope_str = num2cellstr(qc_slope(:),...
            'precision', 0);
        
        % F statistic
        qc_flogp = zeros(size(qcrpt));
        qc_flogp(qcpass) = [qcrpt(qcpass).f_logpval];
        qc_flogp_str = num2cellstr(qc_flogp(:), 'precision', 1);
        
        %Sample IQR
        qc_iqr = zeros(size(qcrpt));
        qc_iqr(qcpass) = [qcrpt(qcpass).iqr];
        qc_iqr_str = num2cellstr(qc_iqr(:), 'precision', 2);
        
        newtags = struct('id', sc.cid,...
            'cal_range', qc_range_str,...
            'cal_fold_change', qc_fold_change_str,...
            'qc_slope', qc_slope_str,...
            'qc_f_logp', qc_flogp_str,...
            'qc_iqr', qc_iqr_str);
        sc = annotate_ds(sc, newtags, 'dim', 'column');
        
        nsample = length(sc.cid);
        %censor bad samples
        if args.censorbad
            mustats = avg_stats(qcrpt);
            bad = bad_samples(mustats);
            cidx_fail = union(bad, cidx_fail);
            dbg(args.verbose, '%d/%d samples failed QC', length(bad), nsample);
        end
        % discard failed samples
        cidx_pass = setdiff(1:nsample, cidx_fail);
        sc = gctextract_tool(sc, 'cid', sc.cid(cidx_pass));
        if args.save_matrix
            scfile = fullfile(args.out, 'norm.gct');
            gctwriter(scfile, sc, 'precision', args.precision);
        end

        qn = sc;
        if ~isempty(cidx_pass)            
            % quantile normalize
            qn.mat = qnorm(sc.mat,...
                'use_sketch', args.use_sketch,...
                'target_sketch', args.target_sketch);
            if args.save_output
                %QC stats
                sdffile = fullfile(args.out, sprintf('qc_n%d.txt', nsample));
                mksdf(sdffile, sc);
                
                %info figure
                hf = myfigure(args.showfig);
                h1 = subplot(2,2,1);
                plot_calib(calib.mat, 'showfig', args.showfig, 'axes', h1, ...
                    'islog2', true, 'showsamples', true);
                title(texify(sprintf('n=%d pass:%d', ...
                    nsample, nnz(qcpass))));
                h2 = subplot(2,2,2);
                plot_quantiles(raw.mat, 'title', 'GEX', 'axes', h2, ...
                    'islog2', true, 'dolegend', false, 'savefig', false, ...
                    'showfig', args.showfig);
                title('GEX')
                h3 = subplot(2,2,3);
                plot_quantiles(sc.mat, 'title', 'NORM', 'axes', h3, ...
                    'islog2', true, 'dolegend', false, 'savefig', false, ...
                    'showfig', args.showfig);
                title('NORM')
                if args.save_matrix
                    qnfile = fullfile(args.out, 'qnorm.gct');
                    gctwriter(qnfile, qn, 'precision', args.precision);
                end
                h4 = subplot(2,2,4);
                % mean cv plot
                muge = mean(qn.mat, 2);
                sigmage = std(qn.mat, 0, 2);
                plot(muge, 100*sigmage./muge, 'b.')
                title('QNORM');
                xlabel('Mean log2 expr.');
                ylabel('%CV');
                xlim([4 15]);
                ylim([0 75]);
                namefig('qcplot');
                
                % calibration FC and
                hf2 = myfigure(args.showfig);
                [maxval, minval] = sample_range(cal_linear);
                rng = maxval - minval;
                fc = maxval ./ minval;
                plot(fc, rng, 'ko');
                axis tight
                xlabel ('Calibration Fold change')
                ylabel ('Calibration Range')
                title (texify(sprintf('n:%d fc:%2.1f range:%2.1f',...
                    nsample, nanmedian(fc), nanmedian(rng))))
                grid on
                ylim([0 8000])
                namefig('rangefc');
                
                savefigures('out', args.out, 'mkdir', false, 'overwrite', true, ...
                    'showfig', false, 'closefig', true);
            end
        else
            dbg(args.verbose, 'No samples passed QC')
        end
        
    else
        dbg(args.verbose, 'No samples to normalize, skipping');
    end
    
    fprintf('-[ %s ]- Stop. (%2.2fs)\n', upper(toolname), toc(start_time));

else
    if isstruct(args.res)
        error('Invalid dataset');
    else
        error('Dataset not found: %s', args.res);
    end
end

end



