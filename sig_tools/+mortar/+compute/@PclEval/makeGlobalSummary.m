function makeGlobalSummary(inpath, cell_lines)
% generate gallery for per cell boxplot

% boxplot locations
%cell_types = mortar.common.Spaces.cell('lincs_core');
%loc = [{'SUMMLY'};cell_types.asCell];
    loc = cell_lines;
    nloc = length(loc);
    has_plot = false(nloc,1);
    plot_path = cell(nloc,1);
    for ii=1:nloc
        [this_fn, this_fp] = find_file(fullfile(inpath, loc{ii}, 'figures', ...
                                                'boxplot_*.png'));
        if ~isempty(this_fn)
            has_plot(ii) = true;
            plot_path{ii} = this_fp{1};
        end
    end
    keep = ~cellfun(@isempty, plot_path);
    if any(keep)
        caption = loc(keep);
        imlist = plot_path(keep);
        this_page = fullfile(inpath, 'global_summary.html');
        mkgallery(this_page, imlist, 'caption', caption,...
                  'title', 'Global Summary', 'ncol', 3, 'width', 315, ...
                  'height', 250)
    else
        warning('No boxplots found, skipping');
    end
end