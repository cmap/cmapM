function [h, quad] = plot_sc(ss, cc, gp, topn, varargin)
% PLOT_SC Display strength correlation plot.

pnames = {'ss_cutoff', 'cc_cutoff', 'showfig',...
    'perm_stat', 'use_std_color', 'legend_location',...
    'marker_size','xlim','ylim',...
    'opacity'};
dflts = {6, 0.25, true,...
    '', true, 'north',...
    7,[-1,1], [0, 20],...
    1};
args = parse_args(pnames, dflts, varargin{:});

ss = ss(:);
cc = cc(:);
gp = gp(:);
myfigure(args.showfig);
hits = ss >= args.ss_cutoff & cc >= args.cc_cutoff;
n = length(ss);
nhit = nnz(hits);
pcthit = 100* nhit / length(hits);
plot(args.xlim, args.ss_cutoff*ones(2,1), '--', 'color', get_color('grey'), 'linewidth', 2)
hold on
plot(args.cc_cutoff*ones(2,1), args.ylim, '--', 'color', get_color('grey'), 'linewidth', 2)
if ~isempty(args.perm_stat)
    scatter(args.perm_stat.cc_q75, args.perm_stat.sig_strength, 'cx');
end
[h, lh, gn] = gpscatter(cc, ss, gp, 'size', args.marker_size, 'location', args.legend_location);
% set(h, 'linewidth', 2);
% color controls green
% ctlidx = ~cellfun(@isempty, regexpi(gn, 'CTL_'));
% set(h(ctlidx), 'markerfacecolor', 'g', 'markeredgecolor', 'k', 'markersize', 7)
if args.use_std_color
    [rgb, sym, isfilled] = get_type_attr(gn);
    set_attr(h, rgb, sym, isfilled, args.marker_size);
end

set(lh,'fontsize',10, 'box', 'off');
text(-0.99, double(args.ss_cutoff), stringify(args.ss_cutoff, 'fmt','%1.2g'),...
    'color', 'r', 'fontsize', 10, 'fontweight','bold',...
    'verticalalignment','bottom')
text(double(args.cc_cutoff)+0.01, 0.1, stringify(args.cc_cutoff, 'fmt','%1.2g'), ...
    'color', 'r', 'fontsize', 10, 'fontweight','bold',...
    'horizontalalignment', 'left')

quad = get_sc_quad(ss, cc, args.ss_cutoff, args.cc_cutoff);
% add percent counts in each quad
x0_lt = args.xlim(1);
x0_rt = args.cc_cutoff;
y0_bot = args.ylim(1);
y0_top = args.ss_cutoff;
xd_lt = abs(args.xlim(1) - args.cc_cutoff);
xd_rt = abs(args.xlim(2) - args.cc_cutoff);

yd_bot = abs(args.ylim(1) - args.ss_cutoff);
yd_top = abs(args.ylim(2) - args.ss_cutoff);

text(x0_lt+0.2*xd_lt, y0_bot+0.25*yd_bot, sprintf('%.1f%%', quad.bot_left), 'fontsize', 20);
text(x0_rt+0.5*xd_rt, y0_bot+0.25*yd_bot, sprintf('%.1f%%', quad.bot_right), 'fontsize', 20);
text(x0_lt+0.2*xd_lt, y0_top+0.8*yd_top, sprintf('%.1f%%', quad.top_left), 'fontsize', 20);
text(x0_rt+0.5*xd_rt, y0_top+0.8*yd_top, sprintf('%.1f%%', quad.top_right), 'fontsize', 20);

% scatter(cc(hits), ss(hits), 'r.');
title(sprintf('n: %d nhits:%d [%2.1f%%]',n, nhit, pcthit));
xlabel('Correlation')
ylabel(sprintf('Signal Strength n:%d', topn))
xlim(args.xlim)
ylim(args.ylim)

if args.opacity<1
    for hi = 1:length(h)
        set_transparency(h(hi), args.opacity);
    end
end

end

function set_transparency(h, opa)
drawnow;
%// get marker handle
hMarkers = h.MarkerHandle; 

%// get current edge and face color
edgeColor = hMarkers.EdgeColorData;
faceColor = hMarkers.FaceColorData;
%// set face color to the same as edge color
faceColor = edgeColor;

%// opacity
%opa = 0.3;

%// set marker edge and face color
hMarkers.EdgeColorData = uint8( [edgeColor(1:3); 255*opa] ); 
hMarkers.FaceColorData = uint8( [faceColor(1:3); 255*opa] ); 
end