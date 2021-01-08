function post_dpeak_figures(platepath, varargin)
% POST_DPEAK_FIGURES Plot figures after dpeak.

if isdirexist(platepath)
    %plate info
    paramfile = fullfile(platepath, 'qc/plate_info.txt');
    plateinfo = parse_param(paramfile);
    pnames = {'lxbhist_analyte', 'lxbhist_well', ...
        'figdir'};
    dflts = {'25,182,286,373,463', 'A5,A05,N13,G17', ...
        fullfile(platepath, 'dpeak/figures')};
    arg = parse_args(pnames, dflts, varargin{:});
    switch plateinfo.detmode
        case 'duo'
            lxbhist_analyte = str2double(tokenize(arg.lxbhist_analyte, ','));
            lxbhist_well = tokenize(arg.lxbhist_well, ',');
            dpeakpath  = fullfile(platepath, 'dpeak');
            
            % FLIP stats
            d = dir(fullfile(dpeakpath, 'flipstats_*.gct'));
            if length(d)==1
                flipstats = parse_gct(fullfile(dpeakpath, d.name));
            else
                error('Flipstats not found at : %s', dpeakpath);
            end
            
            % GENE PAIRS plot
            bsetds = load_bset_ds(platepath, plateinfo, 'GEX');
            plot_gene_pairs(bsetds, lxbhist_analyte, 'out', arg.figdir, ...
                'savefig', true, 'showfig', false,'overwrite',true,...
                'flips', flipstats.mat, 'prefix', 'FIX');
            
            bsetds_raw = load_bset_ds(platepath, plateinfo, 'RAW');
            plot_gene_pairs(bsetds_raw, lxbhist_analyte, 'out', arg.figdir, ...
                'savefig', true, 'showfig', false,'overwrite',true,...
                'flips', flipstats.mat, 'prefix', 'RAW');
            
            % DUO GRADIENT plot
            bsetcnt = load_bset_ds(platepath, plateinfo, 'COUNT');
            plot_duo_gradient(bsetcnt, 'out', arg.figdir, ...
                'savefig', true, 'rpt', plateinfo.plate,'overwrite',true);
            
            % 2D GENE PAIRS plot
            plot_gene_pairs_2d(bsetds, bsetcnt, lxbhist_analyte, 'out', arg.figdir, ...
                'savefig', true, 'showfig', false,'overwrite',true,...
                'flips', flipstats.mat, 'prefix', 'FIX');
            plot_gene_pairs_2d(bsetds_raw, bsetcnt, lxbhist_analyte, 'out', arg.figdir, ...
                'savefig', true, 'showfig', false,'overwrite',true,...
                'flips', flipstats.mat, 'prefix', 'RAW');
                        
            % LXB histograms
            dpeak_param = parse_param(fullfile(dpeakpath, ...
                'detect_lxb_peaks_folder_params.txt'));
            dpeak_arg = param2arg(dpeak_param);
            plot_lxb_hist(lxbhist_analyte, lxbhist_well, dpeak_arg{:}, ...
                'lxbpath', plateinfo.raw_path, ...
                'out', arg.figdir, 'savefig', true,'overwrite',true,...
                'prefix', 'lxbhist');
            % liss dataset
            ds = load_plate_gct(platepath, plateinfo, 'GEX');
            % Quantile plots
            hdr = sprintf('%s GEX', plateinfo.plate);
            plot_quantiles(ds.mat, 'title', hdr, 'name', 'quantiles_gex', ...
                'islog2', false, 'showfig', false, 'out', arg.figdir);
            
            % Flips vs expression difference plot
            myfigure(false);
            abs_diff = median(abs(safe_log2(bsetds(1).ge) - safe_log2(bsetds(2).ge)), 2);
            totflips = sum(flipstats.mat>0, 2);
            pctflips = 100*totflips/size(flipstats.mat,2);
            plot(pctflips, abs_diff, 'ko', 'linewidth', 2)
            axis tight
            xlim([0 100])
            xlabel('% Corrected Flips')
            ylabel('Abs log2 expression diff.')
            title(texify(sprintf('%s Flip correction', ...
                plateinfo.plate)))
            namefig('flipstats');
            
            savefigures('out', arg.figdir, 'mkdir', false, 'overwrite', true);
    end
    close all
else
    error ('%s not found', platepath);
end
end
