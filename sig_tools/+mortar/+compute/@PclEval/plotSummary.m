function plotSummary(rpt, args)
% PLOT_SUMMARY Generate boxplot input
% keep non-nan rows
    rpt = rpt(~isnan([rpt.median_rankpt]));
    ngp = length(rpt);
    %[~, ord] = sort([rpt.median_rankpt], 'descend');
    ord = 1:ngp;
    nel = sum([rpt.group_size]);
    x = zeros(nel, 1);
    group_id = cell(nel, 1);
    group_name = cell(nel, 1);
    pert_iname = cell(nel, 1);
    group_size = zeros(nel, 1);
    ctr = 0;

    for ii=1:ngp
        this = ord(ii);
        this_sz = rpt(this).group_size;
        x(ctr+(1:this_sz)) = rpt(this).row_rankpt;
        group_id(ctr+(1:this_sz)) = {rpt(this).group_id};
        group_name(ctr+(1:this_sz)) = {rpt(this).group_name};
        pert_iname(ctr+(1:this_sz)) = {rpt(this).pert_iname};
        group_size(ctr+(1:this_sz)) = rpt(this).group_size;
        ctr = ctr + this_sz;
    end

    %% Create boxplot
    myfigure(false);

    %         gp = [group_id, pert_iname, num2cellstr(group_size)]';
    %         gplbl = strtrunc(tokenize(sprintf('%s|%s (%s)#', gp{:}),'#'),25);

    gp = [eval(args.boxplot_label_field), num2cellstr(group_size)]';
    gplbl = strtrunc(tokenize(sprintf(['%s(%s)', char(256)],...
        gp{:}),char(256)), 25);
    gplbl = gplbl(1:end-1);

    % reference line at 90 rankpoints
    plot_constant(90, false, 'color', get_color('ochre'),...
        'linewidth', 1.5, 'linestyle', '--');
    hold on
    for ii=1:ngp
        pts = rpt(ord(ii)).row_rankpt;
        isoutlier = pts < rpt(ord(ii)).q25_rankpt - 1.5* ...
            rpt(ord(ii)).iqr_rankpt | pts > rpt(ord(ii)).q75_rankpt + 1.5* ...
            rpt(ord(ii)).iqr_rankpt;

        plot(pts(isoutlier), ii+0.05*randn(nnz(isoutlier), 1), '+',...
            'color', get_color('scarlet'), 'markersize', 4);
        plot(pts(~isoutlier), ii+0.05*randn(nnz(~isoutlier), 1), 'x',...
            'color', get_color('azure'), 'markersize', 4);

    end
    boxplot_opt = {'orientation', 'horizontal', 'symbol', ''};
    if ngp>50
        boxplot_opt = [boxplot_opt, {'plotstyle', 'compact'}];
    end
    bh = boxplot(x, group_id, boxplot_opt{:}, 'labels', gplbl);
    xlim([-100 100])
    axis xy
    boxparent = getappdata(gca, 'boxplothandle');

    % handles of box plots
    % dh = getappdata(boxparent,'datahandles');
    % whiskers are black
    set(findobj(gca,'tag', 'Whisker'), 'color', get_color('grey'));
    % boxes are forest
    set(findobj(gca,'tag', 'Box'), 'color', get_color('forest'), 'linewidth', 1.5);
    % medians are scarlet
    % for standard boxplots
    set(findobj(gca, 'tag', 'Median'),...
        'color', get_color('scarlet'),...
        'MarkerSize', 4,...
        'linewidth', 1.5);
    % for compact style boxplots
    set(findobj(gca, 'tag', 'MedianOuter'),...
        'Marker', 'o',...
        'MarkerSize', 5,...
        'MarkerFaceColor', get_color('scarlet'),...
        'MarkerEdgeColor', get_color('black'))
    set(findobj(gca, 'tag', 'MedianInner'),...
        'Marker', '.',...
        'MarkerEdgeColor', get_color('scarlet'))

    % TOFIX: Broken in 2014b
    % th = getappdata(boxparent, 'labelhandles');
    % set(th,'horizontalalignment', 'right', 'units','normalized',...
    %     'fontsize', 8, 'fontweight', 'normal');
    % nt = length(th);
    % norm_offset = -0.01;
    % for ii=1:nt
    %     pos = get(th(ii), 'position');
    %     set(th(ii), 'position', [norm_offset, pos(2:end)], 'fontweight', 'bold');
    % end
    lh = getappdata(boxparent, 'boxlisteners');
    for ii=1:length(lh)
        delete(lh{ii});
    end
    axpos=get(gca,'position');
    set(gca, 'position', [0.35, axpos(2), 0.5, axpos(end)],...
        'xtick', sort([90, linspace(-100, 100, 9)]), 'fontsize', 11);
    title(sprintf('Concordance of groups (n=%d)',ngp), 'fontsize', 12);
    xlabel(sprintf('Percentile score'));
    namefig('boxplot_rankpt');
end