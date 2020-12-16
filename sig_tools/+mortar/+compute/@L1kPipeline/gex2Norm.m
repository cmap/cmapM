function [ds, calib, sc, qcpass, cal_linear, qn] = gex2Norm(varargin)
    
    pnames = {'ds', 'feature_space', 'yref', 'invset', 'islog2', ...
        'fitmodel', 'precision', 'minval', 'maxval', 'censorbad', ...
        'showfig', 'use_sketch', 'target_sketch', 'use_gctx', ...
        'save_matrix', 'save_output', 'verbose'};
    dflts = {'', 'L1000', '', '', false, 'power', 4, 0, 15, true, ...
        false, false, '', false, true, true, true};
    
    args = parse_args(pnames, dflts, varargin{:});
    
    % res.output = parse_gctx(args.ds);
    ds = parse_gctx(args.ds, 'class', 'double');
    yref = parse_gct(args.yref, 'class', 'double');
    %remove dimensions and '_gex' from filename


    %transform to log2 expression values
    if ~args.islog2
        ds.mat = safe_log2(ds.mat);
    end

    calib = gen_calib_matrix(args.invset, ds);

    if ~isempty(ds.cid)
           dbg(args.verbose, 'Performing invariant-set normalization...');
            [sc, qcrpt, cal, cidx_fail] = liss(ds, calib, yref.mat,...
                'fitmodel', args.fitmodel,...
                    'minval', args.minval, ...
                    'maxval', args.maxval);
        % append quality scores
        % Calib rng
        cal_linear=pow2(cal.mat(:,2:end-2)');
        qc_range = max(cal_linear)-min(cal_linear);
        qc_fold_change = max(cal_linear)./min(cal_linear);
        qc_range_str = num2cellstr(qc_range(:),...
            'precision', 0);
        qc_fold_change_str = num2cellstr(qc_fold_change(:),...
            'precision', 1);

        % Calib slope in degrees for indices that passed.
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
            mustats =  avg_stats(qcrpt);
            bad = bad_samples(mustats);
            cidx_fail = union(bad, cidx_fail);
            dbg(args.verbose, '%d/%d samples failed QC', length(bad), nsample);
        end
        % discard failed samples
        cidx_pass = setdiff(1:nsample, cidx_fail);
        sc = ds_slice(sc, 'cid', sc.cid(cidx_pass));

        qn = sc;
        if ~isempty(cidx_pass)            
            % quantile normalize
            qn.mat = qnorm(sc.mat,...calib
                'use_sketch', args.use_sketch,...
                'target_sketch', args.target_sketch);
        else
            dbg(args.verbose, 'No samples passed QC')
        end
    else
        dbg(args.verbose, 'No samples to normalize, skipping');
    end
    
    output = struct('ds', ds,'calib', calib, 'sc',sc, 'qcpass', qcpass, 'cal_linear', cal_linear, 'qn', qn);
end
