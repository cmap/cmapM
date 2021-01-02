function runInterCellAnalysis(mu_summly, sigma_summly, wkdir)
% Cross cell line analysis
    axlabel = mu_summly.cid;
    gplabel = mu_summly.rid;
    gpsz = ds_get_meta(mu_summly, 'row', 'group_size');
    mu = mu_summly.mat';
    sigma = sigma_summly.mat';
    % Set missing data to zero
    mu(isnan(mu)) = 0;
    sigma(isnan(sigma)) = 0;

    ngp = size(mu, 2);
    out_path = fullfile(wkdir, 'inter_cell');
    fig_path = fullfile(out_path, 'figures');
    imlist = cell(ngp, 1);

    for ii=1:ngp
        myfigure(false);

        h = plot_radar([mu(:,ii), sigma(:,ii)], 'axlabel', axlabel,...
                    'axlim', [-100, 100], 'isfilled', false,...
                    'dimlabel', {'Median Percentile', 'IQR Percentile'});
        set(h(1), 'linewidth', 3);

        title(texify(sprintf('%s (n=%d)', gplabel{ii}, gpsz(ii))));
        name = validvar(gplabel{ii}, '_');
        namefig(name{1});
        imlist(ii) = savefigures('out', fig_path, 'mkdir', false,...
                                'closefig', true, 'overwrite', true);
    end

    mkgallery(fullfile(fig_path, 'index.html'), imlist,...
        'title', 'Inter cell-line Connectivity');

    mkgctx(fullfile(out_path, 'median_rankpt.gctx'), mu_summly);
    mkgctx(fullfile(out_path, 'iqr_rankpt.gctx'), sigma_summly);

end
