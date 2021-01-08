function [h, xx, yy] = plot_raster(x, y, varargin)
% PLOT_RASTER Display a rastergram.
%   PLOT_RASTER(X, Y) plots a vertical tick mark for each X,Y pair.
%   PLOT_RASTER(..., param1, value1,...) Specify optional arguments. Valid
%   options are:
%   'linewidth' : width of the tick mark. Default is 2.
%   'color' : Tick mark color. Default is 'k'
%   'tick_height' : Height of the tick mark, Default is 1.
%   'tick_gap' : Gap between tick marks. Defaults is 0.

narginchk(2, inf)

pnames = {'--linewidth', '--color', '--tick_height',...
          '--tick_gap', '--ytick', '--yticklabel'};
dflts = {2, 'k', 1,...
         0, [], '' };
p = mortar.common.ArgParse(mfilename);
p.add(struct('name', pnames, 'default', dflts));
args = p.parse(varargin{:});

color_num = str2num(args.color);
if ~isempty(color_num) 
    args.color = color_num;
end
numtick = length(x);

xx = nan(numtick*3, 1);
yy = nan(numtick*3, 1);
xx(1:3:end) = x;
xx(2:3:end) = x;
yy(1:3:end) = (y-1)+(y-1)*args.tick_gap;
yy(2:3:end) = yy(1:3:end)+args.tick_height;

h = plot(xx, yy, 'linewidth', args.linewidth, 'color', args.color);
axis tight
if isempty(args.ytick)    
    args.ytick = 0.5*(unique(yy(1:3:end))+unique(yy(2:3:end)));
end
set(gca, 'ytick', args.ytick);

if ~isempty(args.yticklabel)
    set(gca, 'yticklabel', args.yticklabel);
end
