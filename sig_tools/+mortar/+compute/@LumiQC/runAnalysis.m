function res = runAnalysis(varargin)
% LUMIQC   Luminex real-time QC reports.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
[args, help_flag] = getArgs(varargin{:});

if ~help_flag
    res = main(args);
end
end

function [args, help_flag] = getArgs(varargin)
%%% Parse arguments
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', '', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

end

function res = main(args)

res = struct('args', args);
fprintf('##[ %s ]## BEGIN...\n', mfilename);

% control wells (assumes same in all plates)
ctl_wells = parse_tbl(fullfile(mortarconfig('l1k_config_path'), 'L1000_control_wells.txt'));
start_time = tic;
wkdir = args.out;
if ~mortar.util.File.isfile(wkdir, 'dir')
    mkdir(wkdir);
end
try
    if isfileexist(args.in)
        [~,f] = fileparts(args.in);
        plateinfo.plate = f;
        if isempty(args.pool_info)
            args.pool_info = fullfile(mortarconfig('l1k_config_path'), 'L1000_poolinfo.txt');
        end
        [~, pool_annot_dict] = parse_poolinfo(args.pool_info);
        
        if isKey(pool_annot_dict, args.pool)
            annot = pool_annot_dict(args.pool);
            plateinfo.chip = annot.chip_file;
            plateinfo.invset = annot.invset_file;
            plateinfo.yref = annot.yref_file;
        else
            error('Unknown Pool:%s', args.pool)
        end
        % invariant set
        gmx = parse_gmx(plateinfo.invset);
        
        % load csv datasets
        ds = parse_csv(args.in, 'type', {'Median', 'Count'},...
            'mfi_scale_factor', args.mfi_scale_factor);       
        
        % handles bead drop aout
        if ~isequal(length(ds(1).cid), length(ds(2).cid))
            warning('Median and Count sample dimensions dont match, using just common samples')
            cmn_cid = intersect(ds(1).cid, ds(2).cid, 'stable');        
            ds(1) = ds_slice(ds(1), 'cid', cmn_cid);
            ds(2) = ds_slice(ds(2), 'cid', cmn_cid);
        end        
        ds(1).well = ds(1).cid;
        ds(2).well = ds(2).cid;        
        [nAnalyte, nSample] = size(ds(1).mat);
        [nAnalyte_count, nSample_count] = size(ds(2).mat);
        % median and counts should not be empty
        assert(~isempty(ds(1).mat) &&  ~isempty(ds(2).mat),...
            'Dataset is empty : %s', args.in);
        % dimensions of median and counts should match
        assert(isequal(nAnalyte*nSample, nAnalyte_count*nSample_count),...
            'Median and Count dimensions do not match: %s', args.in);
        % all features should be present
        calib_analytes = gen_labels(1:10, 'prefix', 'Analyte ', 'zeropad', false);
        assert(all(ismember(calib_analytes, ds(1).rid)),...
            'Calib genes not found: %s', args.in);
        dbg(1, 'Num Analytes=%d, Num Samples=%d', nAnalyte, nSample);
        if isfileexist(args.map)
            %TODO: FIX for new bead batch update
            % sample map
            welldict = map_samples(args.map, plateinfo, varargin{:});
            wells = get_wellinfo(ds(1).cid);
            vals = welldict.values(wells);
            ds(1).well = ds(1).cid;
            ds(1).cid = cellfun(@(x) x.det_name, vals, 'uniformoutput', false);
            % descriptor dict for each well (one dict per well)
            well_desc = cellfun(@(x) x.sm_desc, vals, 'uniformoutput', false);
            % merge into one dictionary
            ds(1).sdesc = merge_celldict(well_desc);
        else
            % sample map
            wells = get_wellinfo(ds(1).cid);
            dflt_pert = {'TRT'};
            pert_type  = dflt_pert(ones(nSample, 1));
            pert_mfc_desc  = dflt_pert(ones(nSample, 1));
            % Enforce ctl map for all plates except UNI_R.
            if isempty(regexpi(plateinfo.plate, '.*_uni[0-9]*_r.*'))
                [~, widx, ctl_idx] = intersect_ord(wells, ctl_wells.rna_well);
                pert_type(widx) = ctl_wells.pert_type(ctl_idx);
                pert_mfc_desc(widx) = ctl_wells.pert_mfc_desc(ctl_idx);
            end
            
            for ii=1:length(ds)
                ds(ii) = ds_add_meta(ds(ii),'column',{'pert_type','pert_mfc_desc'}, [pert_type, pert_mfc_desc]);
                %             ds(ii).chd = {'pert_type'};
                %             ds(ii).cdesc = pert_type;
                %             ds(ii).cdict = list2dict(ds(ii).chd);
            end
            
            %         dflt_pert = {'TRT'};
            %         pert_type  = dflt_pert(ones(nSample,1));
            %         [~, widx] = intersect_ord(wells, ctl_wells.rna_well);
            %         pert_type(widx) = ctl_wells.pert_type;
            %         ds(1).sdesc = containers.Map('pert_type', pert_type);
        end
        % get Calib Matrices
        calibds = gen_calib_matrix(gmx, ds(1));
        %nCalib = size(calibds(1).mat, 1);                
        %% analysis ouput folders
        fprintf ('Saving analysis to %s\n', wkdir);        
        %% Plots
        % summary report of main qc stats
        report = sample_calib_report(calibds, ds(1));
        qcSummaryFile = fullfile(wkdir, sprintf('qc_report.txt'));
        mktbl(report, qcSummaryFile);
        
        % CSV file meta info
        fid = fopen(fullfile(wkdir, sprintf('csv_info.txt')), 'wt');
        print_args(plateinfo.plate, fid, ds(1).hdr);
        fclose(fid);
        
        %% calibration qc plots
        cal_ylim = [args.cal_ymin, args.cal_ymax];
        qcplots = plot_qc(calibds,...
            'cal_ylim', cal_ylim,...
            'out', args.out, ...
            'rpt', plateinfo.plate, ...
            'showfig', false,...
            'mkplatemap', false,...
            'closefig', true);
        ofile = fullfile(wkdir, 'invlevel');
        mkgct(ofile, calibds, 'precision', args.precision);
        ctrlplots = control_plots(ds(1), ds(2), 'out', args.out, ...
            'rpt', plateinfo.plate,...
            'showfig', false,...
            'closefig', true);
        
        % QC plots
        if isfileexist(plateinfo.yref)
            yref = parse_gct(plateinfo.yref, 'class', 'double');
        else
            error (mfilename, '%s not found', args.yref);
        end
        raw = ds(1);
        raw.ge = safe_log2(raw.mat);
        [sc, qcrpt, cal, qcfail_idx] = liss(raw, calibds, yref.mat, args);
        wn = get_wellinfo({qcrpt.sample});
        wn = setdiff(wn, wn(qcfail_idx));
        excludefigs = findobj('type', 'figure');

        % Level 10
        plot_level_heatmap(calibds.mat(10,:), calibds.cid, plateinfo.plate,...
            'qc_level10', 'title', 'Heat Map of MFI for Invariant Analyte 10',...
            'caxis', cal_ylim)
        
        % Sample median of all raw expression
        medians_raw = median(raw.mat);
        plot_level_heatmap(medians_raw, raw.cid, plateinfo.plate, 'well_median_raw',...
            'title', 'Heat Map of Median Raw MFI for All Analytes');
        
        % Sample median of scaled raw expression
        MMMFI = median(medians_raw);
        medians_scaled = medians_raw/MMMFI;
        plot_scaled_heatmap(medians_scaled, raw.cid, plateinfo.plate, 'well_scaled_median',...
            'title', 'Heat Map of Median Scaled MFI for All Analytes');
        
        % Create Line Plots 
        [~, words] = get_wellinfo(raw.cid, 'plateformat', '384');
        switch args.plate_format
            case {'384'}
                nr = 16;
                nc = 24;
            case {'96'}
                nr = 8;
                nc = 12;
            otherwise        
                error('Unsupported plate size: %s', args.plate_format)
        end
        
        matr = nan(nr, nc);
        matr(words)= medians_raw;  
        rn = textwrap({char(64 + (1:16))},1);
        cn = num2cellstr(1:nc);
        
        myfigure(args.debug);
        column_index = 1:size(matr, 2);
        column_means = mean(matr(:,:), 1.');
        plot (column_index,matr(:,:),'-c','LineWidth',0.05);
        hold on;
        h = plot(column_index,column_means,'-k','LineWidth',1.5, 'Marker', 'o', 'MarkerFaceColor', 'w', 'MarkerSize', 5.5);
        title('Trace of MFI Values over Column Index with Row Mean');
        ax = gca;
        ax.XTick = 1:length(cn);
        ax.XTickLabel = cn;
        xlabel('Columns');
        ylabel('Median Fluorescence Intensity');
        namefig('mfi_rows');
        
        myfigure(args.debug);
        row_index = 1:size(matr, 1);
        row_means = mean(matr(:,:), 2.');
        plot (row_index,matr(:,:),'-c','LineWidth',0.05);
        hold on;
        h = plot(row_index,row_means,'-k','LineWidth',1.5, 'Marker', 'o', 'MarkerFaceColor', 'w', 'MarkerSize', 5.5);
        title('Trace of MFI Values over Row Index with Column Mean');
        ax = gca;
        ax.XTick = 1:length(rn);
        ax.XTickLabel = rn;
        xlabel('Rows');
        ylabel('Median Fluoresence Intensity');
        namefig('mfi_columns');
        
        % F Log P
        if isfield(qcrpt, 'f_logpval')
            qcmetric = [qcrpt.f_logpval];
            fstat = describe(qcmetric);
            lbl = sprintf('%s QC F-LOGP med:%2.0f %%cv:%2.0f', ...
                plateinfo.plate, fstat.median, fstat.robcv);
            plot_platemap(qcmetric, wn, 'title', lbl, 'showfig', false, 'name',...
                'qc_plate_flogp');
            caxis([0 12])
        else
            warning('f_logpval not computed: Skipping qc_plate_flogp')
        end
        
        % IQR
        if isfield(qcrpt, 'iqr')
            qcmetric = [qcrpt.iqr];
            fstat = describe(qcmetric);
            lbl = sprintf('%s QC IQR med:%2.0f %%cv:%2.0f', plateinfo.plate, fstat.median, fstat.robcv);
            
            plot_platemap(qcmetric, wn, 'title', lbl, 'showfig', false, 'name',...
                'qc_plate_iqr');
            caxis([0 20])
        else
            warning('IQR not computed: Skipping qc_plate_iqr')
        end
        
        % Q1
        if isfield(qcrpt, 'q1')
            qcmetric = [qcrpt.q1];
            fstat = describe(qcmetric);
            lbl = sprintf('%s QC Q1 med:%2.0f %%cv:%2.0f', ...
                plateinfo.plate, fstat.median, fstat.robcv);
            plot_platemap(qcmetric, wn, 'title', lbl, 'showfig', false, 'name',...
                'qc_plate_q1');
            caxis([0 12])
        else
            warning('Q1 not computed: Skipping qc_plate_q1')
        end
        
        fnlist = savefigures('out', args.out, 'mkdir', false, ...
            'overwrite', true, 'closefig', true,'exclude', excludefigs);
        mktbl(fullfile(args.out, 'qc_metrics.txt'), qcrpt)
        
        % Create summary report
        params = plateinfo;
        % scan time
        dv = datevec(datenum(ds(1).hdr.BatchStopTime) - datenum(ds(1).hdr.BatchStartTime));
        params.scan_duration = sprintf('%dh %dm',dv(4),dv(5));
        params.scanner_name = sprintf('Scanner %d', sn2scanner(ds(1).hdr.SN));
        params.scanner_sn = ds(1).hdr.SN;
        params.batch = ds(1).hdr.Batch;
        params.scan_date = ds(1).hdr.Date;
        params.protocol = ds(1).hdr.ProtocolName;
        param_order = {'plate';...
            'scan_date';...
            'scan_duration';...
            'scanner_name';...
            'scanner_sn';...
            'protocol'
            'batch';...
            'invset';...
            'yref';...
            'chip';...
            };
        param_order = [param_order; setdiff(fieldnames(params), param_order)];
        params = orderfields(params, param_order);
        mkparam(fullfile(wkdir, sprintf('plate_info.txt')),plateinfo.plate, params)
        if isfileexist(args.map)
            content = get_content(plateinfo.local_map);
            mkparam(fullfile(wkdir, sprintf('plate_content.txt')),plateinfo.plate, content)
        end
        %     imlist = [qcplots; ctrlplots];
        %     imlist = regexprep(imlist ,[wkdir,filesep],'');
        %     texfile = fullfile(wkdir,sprintf('summary_%s.tex', plateinfo.plate));
        %     mktex_figreport(texfile, imlist, 'title', plateinfo.plate, 'arg', params);
        %     pdflatex(texfile, 'cleanup', true)
        
        %close all figs
        close all
        tend = toc(start_time);
        mortar.util.Message.log(fullfile(wkdir, 'success.txt'), ...
            'Completed in %2.2fs', tend);
        fprintf('##[ %s ]## END. (%2.2fs)\n', upper(mfilename), tend);
    else
        fprintf ('File not found %s\n', args.in);
        mortar.util.Message.log(fullfile(wkdir, 'failure.txt'), ...
            'File not found %s\n', args.in);
    end
catch e
    mortar.util.Message.log(1, e);
    if ~isempty(wkdir)
        err_file = fullfile(wkdir, 'failure.txt');
        mortar.util.Message.log(err_file, e);
        mortar.util.Message.log(1, 'Stack trace saved in %s', err_file);
    end
end
end
