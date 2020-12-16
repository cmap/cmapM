function varargout = plot_radar(varargin)
% PLOT_RADAR spiderweb or radar plot
% radarPlot(P) Make a spiderweb or radar plot using the columns of P as datapoints.
%  P is the dataset. The plot will contain M dimensions(or spiderweb stems)
%  and N datapoints (which is also the number of columns in P). Returns the
%  axes handle
%
% radarPlot(P, ..., lineProperties) specifies additional line properties to be
% applied to the datapoint lines in the radar plot
%
% h = radarPlot(...) returns the handles to the line objects.

% Adapted from:
% http://www.mathworks.com/matlabcentral/fileexchange/33134-radar-plot/content/radarPlot.m

pnames = {'axlabel', 'axlim', 'isfilled', 'dimlabel', 'ntick', 'tick',...
    'label_orientation','fontsize'};
dflts = {'', [], false, '', 11, [], 'linear', 8};

% Parse possible Axes input
[cax, args, nargs] = axescheck(varargin{:});

P = args{1};
% find first string argument
[reg, pvpairs] = parseparams(args);

% extract local parameters
[local_args, ext_args] = get_local_params(pvpairs, pnames);
args = parse_args(pnames, dflts, local_args{:});

use_radial_labels = strcmpi('radial', args.label_orientation);

%%% Get the number of dimensions and points
[M, N] = size(P);

%%% Plot the axes
% Radial offset per axis
% th = pi/2 - (2*pi/M)*(ones(2, 1)*(M:-1:1));
th = pi/2 - (2*pi/M)*(ones(2, 1)*(0:M-1));
% Axis start and end
r = [0;1]*ones(1,M);
% Conversion to cartesian coordinates to plot using regular plot.
[x,y] = pol2cart(th, r);
hLine = line(x, y,...
    'LineWidth', 0.75,...
    'linestyle', '-',...
    'Color', [1, 1, 1]*0.7  );

for ii = 1:numel(hLine)
    set(get(get(hLine(ii),'Annotation'),'LegendInformation'),...
        'IconDisplayStyle','off'); % Exclude line from legend
end

toggle = ~ishold;

if toggle
    hold on
end

%%% Plot axes isocurves
% Radial offset per axis
% th = pi/2 - (2*pi/M)*(ones(args.ntick, 1)*(M:-1:1));
th = pi/2 - (2*pi/M)*(ones(args.ntick, 1)*(0:M-1));
% Axis start and end
r = (linspace(0.1, 0.9, args.ntick)')*ones(1,M);
% Conversion to cartesian coordinates to plot using regular plot.
[x, y] = pol2cart(th, r);
hLine = line([x, x(:,1)]', [y, y(:,1)]',...
    'LineWidth', 1, 'linestyle', ':',...
    'Color', [1, 1, 1]*0.75  );
for ii = 1:numel(hLine)
    set(get(get(hLine(ii),'Annotation'),'LegendInformation'),...
        'IconDisplayStyle','off'); % Exclude line from legend
end


%%% Insert axis labels

% Compute minimum and maximum per axis
if isempty(args.axlim)
    minV = min(P,[],2);
    maxV = max(P,[],2);
else
    % fixed axis
    minV = args.axlim(1)*ones(M, 1);
    maxV = args.axlim(2)*ones(M, 1);
    % Add axis ticks
    axtick = num2cellstr(linspace(minV(1), maxV(1), args.ntick));
    text(x(:, 1), y(:, 1), axtick,...
        'fontsize', args.fontsize,...
        'color', 'k',...
        'horizontalalignment', 'center');

%     for ii=1:size(r, 1);
%         %     line([-1.25, -1.2], [y(ii, 1), y(ii, 1)], 'color', 'k');
%     end
end

if use_radial_labels
    ang = 90-(0:M-1)*360/M;
    ang(abs(ang)>90)=180+ang(abs(ang)>90);
end

for jj = 1:M
    % Generate the axis label    
    if isempty(args.axlabel)
        msg = sprintf('x_{%d}[%2.1f...%2.1f]',...
            jj, minV(jj), maxV(jj));
    else
        msg = args.axlabel{jj};
    end
    [mx, my] = pol2cart( th(1, jj), 1.2);
    t=text(mx, my, msg, 'horizontalalignment', 'center');
    % Added option to print axes labels radially
    t.FontSize = args.fontsize;
    if use_radial_labels
        t.Rotation = ang(jj);
    end
end
axis([-1, 1, -1, 1]*1.25)

% Hold on to plot data points
hold on

% Radius

R = 0.8*((P - (minV*ones(1,N)))./((maxV-minV)*ones(1,N))) + 0.1;
R = [R; R(1,:)];
% Th = pi/2 - (2*pi/M) * ((M:-1:0)'*ones(1,N));
Th = pi/2 - (2*pi/M) * ((0:M)'*ones(1,N));

% polar(Th, R)
[X, Y] = pol2cart(Th, R);

if args.isfilled
    fill_color = get_palette(N);
    h = fill(X, Y, 'b', ext_args{:});
    for ii=1:N
        set(h(ii), 'facecolor', fill_color(ii, :), 'facealpha', 0.6,...
            'edgecolor', fill_color(ii, :), 'edgealpha', 0.85);
        %         'marker','o', 'markersize', 10, 'markeredgecolor','k');
    end
else
    line_color = get_palette(N);
    h = plot(X, Y, ext_args{:});
    for ii=1:N
        set(h(ii), 'color', line_color(ii, :),...
            'marker', 'o', 'markersize', 4,...
            'markerfacecolor', line_color(ii, :),...
            'linewidth',1);
    end
end

% add legend
if ~isempty(args.dimlabel)
    legend(args.dimlabel, 'location', 'southoutside',...
        'orientation', 'horizontal')
    legend boxoff
end

% axis([-1, 1, -1, 1])
axis square
axis off

if toggle
    hold off
end

if nargout > 0 
    varargout{1} = h;
end
