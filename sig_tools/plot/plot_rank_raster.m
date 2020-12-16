function [h, pobj] = plot_rank_raster(r, ygp, varargin)
% PLOT_RANK_RASTER Plot rankpoints as a rastergram.
%   PLOT_RANK_RASTER(R, YGP) Plots the raster for ranks R and the grouping variable YGP.

pnames = {'--color', '--title', '--name',...
          '--linewidth', '--yticklabel', '--y2ticklabel',...
          '--y2label'};
dflts = {'r', '', '',...
         2, '_default', '',...
         ''};
p = mortar.common.ArgParse(mfilename);
p.add(struct('name', pnames, 'default', dflts));
args = p.parse(varargin{:});

[~, srtidx] = sort(ygp);
srtidx = srtidx(end:-1:1);
srt_ygp = ygp(srtidx);
r = r(srtidx);
[gp, y] = getcls(srt_ygp);

numgp = length(gp);

if isequal(args.yticklabel, '_default')
    % use group values, pass yticklabel='' to disable.
    args.yticklabel = gp;
end

[h, xx, yy] = plot_raster(r, y, 'linewidth', args.linewidth,...
            'color', args.color, 'yticklabel', args.yticklabel,...
            'tick_gap', 0.2);
xlim([-101 101]);
xtick = linspace(-100, 100, 9);
set(gca, 'xtick', xtick, 'tickdir', 'out', 'ygrid', 'off');
% set(gca, 'xtick', linspace(-100, 100, 9), 'tickdir', 'out',...
%     'xcolor', ones(3,1)*0.6, 'ycolor', ones(3,1)*0.6);
xlabel('Rankpoint')

% set x and y axis labels to black
% caxes = copyobj(gca, gcf);
% set(caxes,'color','none', 'ycolor','k', 'ygrid','off', 'xcolor','k', 'xgrid','off')
if ~isempty(args.y2ticklabel)
    [~, label_idx] = intersect_ord(ygp, gp);
    y2ticklabel = args.y2ticklabel(label_idx);
    ax1 = gca;
    ax2 = axes('Position', get(ax1, 'Position'),...
        'YAxisLocation', 'right', 'color', 'none');
    set(ax2, 'ylim', get(ax1, 'ylim'),...
        'ytick', get(ax1, 'ytick'), 'yticklabel', y2ticklabel,...
        'ycolor', get_color('blue'), 'fontweight', 'normal',...
        'fontsize', 10, 'ygrid', 'off', 'tickdir', 'out',...
        'xtick', get(ax1,'xtick'), 'xticklabel', '');
    ylabel(args.y2label, 'fontsize', 9, 'fontweight', 'bold', 'color', 'b');
    axesoff(ax1);    
end

if ~isempty(args.title)
    title(args.title);
    [~, name] = validate_fname(lower(args.title));
    namefig(name);
end

if ~isempty(args.name)
    namefig(args.name);
end
pobj = struct('x', r, 'y', y, 'ygp', {gp}, 'args', args);
end