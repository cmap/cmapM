function plotPWMatrix(rpt, cluster_method, args)
% plot pw matrices
ngset = length(rpt);
assert(isfield(rpt, args.heatmap_label_field),...
        'Heatmap label field %s not found',...
        args.heatmap_label_field)
assert(isfield(rpt, 'pert_id'),...
        'Heatmap label field pert_id not found')    
hm_label_field = args.heatmap_label_field;
for ii=1:ngset
    nx = rpt(ii).group_size;
    dbg(1, '%d/%d %s (%d)', ii, ngset, rpt(ii).group_id, nx);
    if nx >1
        x = rpt(ii).pw_rankpt;
        % set nans to zero for clustering
        inan = isnan(x);
        x0 = x;
        x0(inan) = 0;
        myfigure(false);
        switch (cluster_method)
            case 'hclust'
                % re-order matrix based on hclust
                d = tri2vec(50-(x0/2), 1, false)';
                tree = linkage(d, 'complete');
                ord = optimalleaforder(tree, d);
            case 'median'
                % reorder based on median of medians
                mux = median(x0);
                [~, ord] = sort(mux, 'descend');
            otherwise
                error ('Invalid cluster method:%s', cluster_method);
        end
        ylbl = tokenize(rpt(ii).(hm_label_field), '|');
        xlbl = tokenize(rpt(ii).pert_id, '|');
        ylbl = ylbl(ord);
        xlbl = xlbl(ord);
        short_ylbl = strtrunc(ylbl, 25);
        short_xlbl = strtrunc(xlbl, 25);
        
        % set nans to grey
        cm = str2func(args.colormap);
        imagescnan(x(ord, ord), cm(), get_color('grey'), [-100,100]);
        axis square
        grid off
        set(gca, 'fontsize', 6);
        set(gca, 'xtick', 1:length(short_xlbl), 'xticklabel', short_xlbl);
        set(gca, 'ytick', 1:length(short_ylbl), 'yticklabel', short_ylbl);
        rotateticklabel(gca, 45);
        title_str = strtrunc(rpt(ii).group_id, 40);
        title(texify(sprintf('%s (n=%d) med:%2.1f q25:%2.1f q75:%2.1f',...
                             title_str, nx, rpt(ii).median_rankpt,...
                             rpt(ii).q25_rankpt, rpt(ii).q75_rankpt)),...
              'fontsize', 10);
        outname = lower(validvar(sprintf('heatmap_%s', rpt(ii).group_id), '_'));
        namefig(outname{1});
    else
        dbg(1, 'singleton, skipping');
    end
end
end