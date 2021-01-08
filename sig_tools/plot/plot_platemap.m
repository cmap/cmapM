function h = plot_platemap(x, wells, varargin)
% PLOT_PLATEMAP Project variable on a platemap view
% H = PLOT_PLATEMAP(X, W) plots variable X at the corresponding well
% location W on a 384 well plate map layout. X can be numeric or a cell
% array in the case of categorical variables.
%
% H = PLOT_PLATEMAP(X, W, 'PARAM1', VALUE1, ...) specify optional
% parameters:
%
%  'discrete' : boolean, Plots X as a discrete variable if true. 
%               Default is false
%  'title'    : string, plot title. Default is ''
%  'colormap' : string, Valid Matlab colormap. Default is 'jet'
%  'showfig'  : boolean, Hide figure if false. Default is true
%  'name'     : string, plot name. Default is ''
%  'doleg'    : boolean Generates legend as a separate plot. Default is true
%  'flagwell' : numeric array, Vector of indices into X that should be
%               flagged. Default is none
%  'flagsym'  : string, marker color and symbol to use for flagged values.
%               Default is 'ko'
%  'nansym'   : string, marker color and symbol to use for NaN values. 
%               Default is 'wx'
%  'caxis'    : [cmin, cmax] two-element vector specifying color axis scaling,
%               Default is auto scaling
%  'palette'  : structure, specify custom color and symbol palette for discrete
%               variables. Example:
%               palette = struct('id', {'a','b','c','d'}, ...
%                        'color', {[1,0.5,0.5],'g','b','y'}, ...
%                        'marker', {'o','s','v','*'})
%  'bg_color' : color_spec, background color. Default is black 'k'
%  'ylabelrt' : string, Right sided Y-axis label, Default is ''
%  'plateformat' : string, Plate layout to use. Choices are {'384', '96'}.
%                  Default is '384'
%
% Examples
%   rows=cellstr(char(64+(1:16))');
%   cols=num2cellstr(1:24);
%   W = strcat(repmat(rows,1,24),repmat(cols,16,1));
%   X = randn(16, 24);
%   plot_platemap(sort(X), W)
%   X2 = num2cellstr(X>2);
%   plot_platemap(X2, W, 'discrete', true)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

toolName = mfilename;
pnames = {'title', 'colormap', 'discrete',...
          'showfig', 'name', 'doleg',...
          'flagwell', 'flagsym','nansym'...
          'caxis', 'palette', 'bg_color',...
          'ylabelrt', 'plateformat'};
dflts = {'', 'jet', false, ...
        true, '', true,...
        [], 'ko','wx',...
        [], '', 'k', '',...
        '384'};

arg = parse_args(pnames, dflts, varargin{:});

switch arg.plateformat
    case {'384'}
        nr = 16;
        nc = 24;
    case {'96'}
        nr = 8;
        nc = 12;
    otherwise        
        error('Unsupported plate size: %s', arg.plateformat)
end

x = x(:);
[wn, word] = get_wellinfo(wells, 'plateformat', arg.plateformat);

% x is a continuous variable, use heatmap
if ~arg.discrete
    myfigure(arg.showfig);
    y = nan(nr, nc);
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
    cn = num2cellstr(1:nc);    
    set(gca,'xtick', 1:nc, 'xticklabel', cn,...
        'ytick', 1:nr,'yticklabel', rn,...
        'fontweight', 'bold',...
        'tickdir', 'out')    
    ha = rotateticklabel(gca, 90);

    nudge_ticklabels(ha, 0.5);    
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
    [ir, ic] = ind2sub([nr, nc], word);
    % groups sorted alphabetically
    gp = sort(getcls(x));
    ngp = length(gp); 
    if isempty(arg.palette)
        % Auto generate palette
        col = get_linestyle(ngp, 'attr','col', 'col', 'rgcbmy');
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
    xlim([0.5 nc+0.5])
    ylim([0.5 nr+0.5])
    rn = textwrap({char(64 + (1:16))},1);
    cn = num2cellstr(1:nc);
    set(gca,'xtick', 1:nc, 'xticklabel', cn,...
        'ytick', 1:nr,'yticklabel', rn,...
        'fontweight', 'bold',...
        'tickdir', 'out','color', arg.bg_color)
    ha = rotateticklabel(gca, 90);
    nudge_ticklabels(ha, 0.5);    
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
end

function nudge_ticklabels(ha, val)
% nudge xtick labels
pos = get(ha,'position');
newpos = cellfun(@(x) x + [0, val, 0], pos, 'unif', false);
set(ha, {'position'}, newpos);
end