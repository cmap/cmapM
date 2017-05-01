function fh = plot_calib(calibmat, varargin)
%% PLOT_CALIB Create calibration plot.

pnames = {'showfig', 'group', 'sl', ...
    'showsamples', 'keepsamples', 'ylim',...
    'title','axes', 'islog2'};
dflts =  { true, '', '', ...
    false, [], [0 8000],...
    '', -666.0, false};
arg = parse_args(pnames, dflts, varargin{:});

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
        fh = axes(arg.axes);
    else
        fh = axesoff(arg.axes);
    end
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
            'col', 'yrbgcm', 'dash', '-,--,.-');
        hp = zeros(ngp, 1);
        for ii=1:ngp
            gpidx = arg.keepsamples(gpvar==srtgp(ii));
            hx = plot(xtick, calibmat(:, gpidx), style{ii});    
            if strncmp('LMA_', gplbl{ii}, 4) && srtsz(ii) < 5
                set(hx, 'linewidth', 2)
            end
            hp(ii) = hx(1);
            hold on
            gplbl{ii} = texify(sprintf('%s (%d)', gplbl{ii}, srtsz(ii)));
        end        
    else
        hp = plot (xtick, calibmat(:, arg.keepsamples), 'color', ones(1,3)*0.75);
        hold on
    end    
end
% mean with error bar
h = errorbar(xtick, curveMu, curveStd);
cal_min = min(curveMu);
cal_max = max(curveMu);
cal_ratio = cal_max ./ max(cal_min, 1);
title(texify(sprintf('%s min:%4.0f max:%4.0f ratio:%2.1f', ...
    arg.title, cal_min, cal_max, cal_ratio)));
set(h, 'color', 'k', 'marker', 'o', ...
    'markerfacecolor', 'w', 'markersize', 7, ...
    'linewidth', 2, 'linestyle', '--');
set(gca, 'xtick', xtick);

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

