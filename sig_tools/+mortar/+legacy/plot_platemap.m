function h = plot_platemap(x, wells, varargin)

% Specify a custom palette for discrete variables
% palette = struct('id', {'a','b','c','d'}, ...
%     'color', {[1,0.5,0.5],'g','b','y'}, ...
%     'marker', {'o','s','v','*'})
% Specify a different background color with variable bg_color
%   Default is black

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

toolName = mfilename;
pnames = {'title', 'colormap', 'discrete',...
          'showfig', 'name', 'doleg',...
          'flagwell', 'flagsym','nansym'...
          'caxis', 'palette', 'bg_color', 'ylabelrt'};
dflts = {'', 'jet', false, ...
        true, '', true,...
        [], 'ko','wx',...
        [], '', 'k', ''};
arg = parse_args(pnames, dflts, varargin{:});

[wn, word] = get_wellinfo(wells);

% x is a continuous variable, use heatmap
if ~arg.discrete
    myfigure(arg.showfig);
    y = nan(16,24);
    y(word)= x;    
    h = imagesc(y);
    % set missing to white
    % changing alpha data, causes segfaults
    % set(h,'alphadata', ~isnan(y));
    if any(isnan(y(:)))
        [r, c] = find(isnan(y));
        hold on
        plot (c, r, arg.nansym,'markersize', 8, 'linewidth', 2)
    end
    if ~isempty(arg.flagwell)
        [r, c] = ind2sub(size(y), arg.flagwell);
        hold on
        plot (c, r, arg.flagsym,...
            'markersize', 6, 'linewidth', 2)
    end
    %row and column names
    rn = textwrap({char(64 + (1:16))},1);
    cn = num2cellstr(1:24);    
    set(gca,'xtick', 1:24, 'xticklabel', cn,...
        'ytick', 1:16,'yticklabel', rn,...
        'fontweight', 'bold',...
        'tickdir', 'out')    
    ha = rotateticklabel(gca,90);
    set(ha,'fontweight', 'bold','verticalalignment','middle');    
    if ~isempty(arg.title)
        title(texify(arg.title));
    end    
    colormap(arg.colormap);    
    colorbar
    if ~isempty(arg.name)
        namefig(arg.name);
    end
    if ~isempty(arg.caxis)
        caxis(arg.caxis);
    end
    if ~isempty(arg.ylabelrt)
        ylabelrt(texify(arg.ylabelrt), 'color', 'b');
    end
else
    % x is discrete, use gscatter with glyphs
    myfigure(arg.showfig);
    [ir, ic] = ind2sub([16 24], word);
    % groups sorted alphabetically
    gp = sort(getcls(x));
    ngp = length(gp); 
    if isempty(arg.palette)
        % Auto generate palette
        col = get_linestyle(ngp, 'attr','col', 'col', 'rgcbmyk');
        marker = get_linestyle(ngp, 'attr', 'sym', 'sym','osh*pv');
        arg.palette = struct('id', gp, 'color', col, 'marker', marker);
        gp_attr = list2dict({arg.palette.id});
    elseif isstruct(arg.palette)
        % Custom palette        
        assert (all(ismember(fieldnames(arg.palette), ...
            {'id', 'color', 'marker'})), 'Invalid palette structure');        
        % check if all groups are specified
        gp_attr = list2dict({arg.palette.id});
        if ~all(gp_attr.isKey(gp))
            disp(gp(~gp_attr.isKey(gp)));
            error('Attributes not specified for some groups')
        end
    else
        error('Invalid palette');
    end
    
    [h, ~, gn] = gpscatter(ic, ir, x, ...
        'doleg', arg.doleg, 'location', 'northeastoutside', ...
        'siz', 13, 'xnam', '', 'ynam', '');

    for ii=1:ngp
        set (h(ii), 'color', arg.palette(gp_attr(gn{ii})).color,...
            'marker', arg.palette(gp_attr(gn{ii})).marker,...
            'markerfacecolor', arg.palette(gp_attr(gn{ii})).color)
    end
    axis ij
    xlim([0.5 24.5])
    ylim([0.5 16.5])
    rn = textwrap({char(64 + (1:16))},1);
    cn = num2cellstr(1:24);
    set(gca,'xtick', 1:24, 'xticklabel', cn,...
        'ytick', 1:16,'yticklabel', rn,...
        'fontweight', 'bold',...
        'tickdir', 'out','color', arg.bg_color)
    ha = rotateticklabel(gca, 90);
    set(ha,'fontweight', 'bold');
    ylabel ('');
    % needed for saving with the black background
    set(gcf, 'InvertHardcopy', 'off')
    if ~isempty(arg.title)
        title(texify(arg.title));
    end
    if ~isempty(arg.name)
        namefig(arg.name);
    end
    if ~isempty(arg.ylabelrt)
        ylabelrt(texify(arg.ylabelrt), 'color', 'b');
    end
    %legend in a separate figure
    myfigure(arg.showfig);
    for ii=1:ngp         
        h = plot(1, 0.5*ii, ...
            'marker', arg.palette(gp_attr(gp{ii})).marker, ...
            'color', arg.palette(gp_attr(gp{ii})).color, ...
            'markersize', 13, ...
            'markerfacecolor', arg.palette(gp_attr(gp{ii})).color);
        hold on
        text(1.05, 0.5*ii, texify(gp{ii}), ...
            'fontweight', 'bold', 'fontsize', 14, ...
            'verticalalignment', 'middle');        
    end
    axis ij
    grid off
    axis tight
    lims = axis;
    ylim ([0.25 0.5*ngp+0.25])
    xlim([1 lims(2)])
    axis off

    if ~isempty(arg.name)
        namefig(sprintf('legend_%s', arg.name));
    end

end