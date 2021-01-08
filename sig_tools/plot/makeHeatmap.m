function [figure1, xord, yord] = makeHeatmap(ds, varargin)

    pnames = {'cluster_method', ...
        'row_annots', ...
        'col_annots', ...
        'show_figure', ...
        'sort_fields', ...
        'fig_size', ...
        'colormap', 'scale_max'};

    dflts = {'none', {'pert_iname'}, ... 
        {'pert_iname'}, ... 
        true, ...
        {}, ...
        723, 'taumap_redblue90', 100};

    args = parse_args(pnames, dflts, varargin{:});

%    thresh = 95;
    figsz = args.fig_size;
    %trim_labels = 0;
    %figure1 = figure();
    if args.show_figure
        figure1=figure('position', [ 1, 162, 1.2*figsz, figsz]);
    else
        figure1=figureoff('position', [ 1, 162, 1.2*figsz, figsz]);
    end
    
    x = ds.mat;
    inan = isnan(x);
    x0 = x;
    x0(inan) = 0;
    
    %generate labels
    for jj = numel(args.col_annots):-1:1
        if jj == numel(args.col_annots)
            xlbl = cellfun(@(x) {num2str(x)}, ds.cdesc(:,ds.cdict(args.col_annots{jj})));
        else
            xlbl = cellfun(@(x,y) sprintf('%s | %s', x, num2str(y)), ...
                xlbl,ds.cdesc(:,ds.cdict(args.col_annots{jj})),'un',0);            
        end
    end
    for kk = numel(args.row_annots):-1:1
        if kk == numel(args.row_annots)
            ylbl = cellfun(@(x) {num2str(x)}, ds.rdesc(:,ds.rdict(args.row_annots{kk})));
        else
            ylbl = cellfun(@(x,y) sprintf('%s | %s', x, num2str(y)), ...
                ylbl,ds.rdesc(:,ds.rdict(args.row_annots{kk})),'un',0);
        end
    end

    
    cm = str2func(args.colormap);
    switch (args.cluster_method)
        case 'hclust'
            % re-order matrix based on hclust
            d = tri2vec(50-(x0/2), 1, false)';
            tree = linkage(d, 'complete');
            ord = optimalleaforder(tree, d);
            xord = ord;
            yord = ord;
        case 'median'
            % reorder based on median of medians
            mux = median(x0);
            [~, xord] = sort(mux, 'descend');
            yord = xord;
        case 'fields'
            tab = gctmeta(ds);
            tab = struct2table(tab, 'AsArray', true);
            [~,ord]  = sortrows(tab,args.sort_fields);
            xord = ord;
            yord = ord;
        otherwise
            xord = 1:numel(ds.cid);
            yord = 1:numel(ds.rid);
    end    
    
    ylbl = ylbl(yord);
    xlbl = xlbl(xord);
    short_ylbl = ylbl;
    %short_ylbl = strtrunc(ylbl, 25);
    short_xlbl = strtrunc(xlbl, 25);
    
%     if (trim_labels)
%         curr = short_xlbl{1};
%         for ii=2:numel(short_xlbl)
%             if (strcmp(curr,short_xlbl{ii}))
%                 %short_ylbl{ii} = '';
%                 short_xlbl{ii} = '';
%             else
%                 %short_ylbl{ii-1} = curr;
%                 short_xlbl{ii-1} = curr;
%                 curr = short_xlbl{ii};
%             end
%         end
%     end
    
    %add spacing on x axis for readability
    %short_xlbl = cellfun(@(x) [x '   x'], short_xlbl, 'UniformOutput', 0);   
    
    imagescnan(x(yord, xord), cm(), get_color('grey'), [-args.scale_max, args.scale_max]);
    set(gca, 'position', [0.0500    0.1100    0.7379    0.8150])
    set(gca, 'FontUnits', 'normalized')
    set(gca, 'FontSize', min(1/numel(short_xlbl),0.016));
    set(gca, 'xtick', 1:length(short_xlbl), 'xticklabel', short_xlbl);
    set(gca, 'ytick', 1:length(short_ylbl), 'yticklabel', short_ylbl);
    %if (figsz > 1000), fontsz = 12; else, fontsz = 12; end
    %title({sprintf('moa: %s', plt_name),sprintf('noff_diag: %d, n_cps: %d', noff_diag, n_cps)}, 'FontSize', fontsz, 'Interpreter','none');
    set(gca, 'XAxisLocation', 'bottom')
    set(gca, 'TickDir', 'out')
    set(gca, 'TickLength', [0.005, 0.025]);
    set(gca, 'YAxisLocation', 'right')
    set(gca, 'TickLabelInterpreter', 'none');
    colorbar('off')
    c = colorbar;
    set(c, 'position', [0.84, 0.80, 0.0186, 0.1])
    set(gca, 'XTickLabelRotation', -90)
end