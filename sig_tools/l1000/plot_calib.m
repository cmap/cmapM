function fh = plot_calib(calibmat, varargin)
%% PLOT_CALIB Display calibration plot.
%   H = PLOT_CALIB(CM) CM is a numeric matrix of calibration set values
%   with dimensions L Invariant sets x S Samples
%
%   H = PLOT_CALIB(CM, 'name1', value1,...) Specify name-value pairs
%   'showfig': boolean, hide figure if false. Default true
%   'group': cell array, grouping variable used to stratify the plot
%   'showsamples' : boolean, shows per-sample curves if true. Default is
%   false.
%   'keepsamples' : numeric or boolean column index, 
%   'ylim' : 2 element vector, Y-axis limit. Default is [0, 8000]
%   'title': string, Title string Default is ''
%   'axes' : axis handle. Displays plot on specified axes if provided.
%   Default is ''
%   'islog2': boolean, Default is false
%   'linewidth' : integer, width of plotted lines. Default is 1
%   'showmean' : boolean. Show the mean calibration curve if true. Default is true
%   'group_color': string. Color specifcation string. Default is 'yrbgcm'

pnames = {'showfig', 'group', 'sl', ...
    'showsamples', 'keepsamples', 'ylim',...
    'title', 'axes', 'islog2',...
    'linewidth', 'showmean', 'group_color'};
dflts =  { true, '', '', ...
    false, [], [0 8000],...
    '', '', false,...
    1, true, 'yrbgcm'};
arg = parse_args(pnames, dflts, varargin{:});
lma_x = {'bo', 'rmcf7', 'pmcf7'};
lma_color = {'maroon','forest','indigo'};
[nLevel,nSample] = size(calibmat);
xtick = (1:nLevel)';

if isempty(arg.keepsamples)
    arg.keepsamples = 1:nSample;
else
    nSample = length(arg.keepsamples);
end

if ~isempty(arg.sl)
    arg.sl = texify(arg.sl);
else
    arg.sl= num2str((1:nSample)');
end
% if ds is in log2 convert to linear scale
if arg.islog2
    calibmat = pow2(calibmat);
end
% exclude LMA controls if group is specified
if ~isempty(arg.group)
    nonlma = ~strncmpi('LMA_', arg.group, 4);
else
    nonlma = arg.keepsamples;
end
curveMu = nanmean(calibmat(:, arg.keepsamples(nonlma)), 2);
curveStd = nanstd(calibmat(:, arg.keepsamples(nonlma)), 0, 2);
if ishandle(arg.axes)
    if arg.showfig
        axes(arg.axes);        
    else
        axesoff(arg.axes);        
    end
    fh = gcf;
else
    fh = myfigure(arg.showfig);
end

if arg.showsamples
    if ~isempty(arg.group)
        [gplbl, gpvar] = getcls(arg.group(arg.keepsamples));
        ngp = length(gplbl);
        gpsz = accumarray(gpvar, ones(size(gpvar)));
        [srtsz, srtgp]=sort(gpsz, 'descend');
        gplbl = gplbl(srtgp);
        style = get_linestyle(ngp, 'attr', 'col,dash', ...
            'col', arg.group_color, 'dash', '-,--');
        hp = zeros(ngp, 1);
        for ii=1:ngp
            gpidx = arg.keepsamples(gpvar==srtgp(ii));
            hx = plot(xtick, calibmat(:, gpidx), style{ii});    
            islma = ismember(lma_x, lower(gplbl{ii}));
            if  any(islma) && srtsz(ii) < 5
                set(hx, 'linewidth', 2, 'linestyle', '-.', 'color', get_color(lma_color{islma}));
            end
            hp(ii) = hx(1);
            hold on
            gplbl{ii} = texify(sprintf('%s (%d)', gplbl{ii}, srtsz(ii)));
        end        
    else
        hp = plot (xtick, calibmat(:, arg.keepsamples),...
            'color', ones(1,3)*0.75,...
            'linewidth', arg.linewidth);
        hold on
    end    
end
% mean with error bar
if arg.showmean
    h = errorbar(xtick, curveMu, curveStd);
    cal_min = min(curveMu);
    cal_max = max(curveMu);
    cal_ratio = cal_max ./ max(cal_min, 1);
    title(texify(sprintf('%s min:%4.0f max:%4.0f ratio:%2.1f', ...
        arg.title, cal_min, cal_max, cal_ratio)));
    set(h, 'color', get_color('blue'), 'marker', 'o', ...
        'markerfacecolor', 'w', 'markersize', 7, ...
        'linewidth', 2, 'linestyle', '--');
    set(gca, 'xtick', xtick);
end

if ~isempty(arg.group)
     [legend_h,object_h]  = legend (hp, gplbl, 'location', 'best');
     set(object_h,'linewidth', 2);
     set(findobj(object_h, 'type','text'),'fontsize',12)
     set(legend_h, 'Box', 'off')
     set(legend_h, 'Color', 'none')
else
    legend (h, 'Mean', 'location', 'northwest');
end
xlabel ('Invariant set');
ylabel ('Median Expression');
xlim([xtick(1)-0.5 xtick(end)+0.5])
ylim (arg.ylim)
grid on

end