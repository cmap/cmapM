function ah = plot_header(cl,ph,varargin)
% PLOT_HEADER color coded class header bars
%   EDG = PLOT_HEADER(CL,CN,NL,H)
%
% Example
%   x=magic(5)
%   figure
%   imagesc(x)
%   ha = gca;
%   cl=[{'a';'a';'b';'b';'c'},{'foo';'foo';'foo';'bar';'bar'}];
%   ahe = plot_header(cl, ha);
%   ahn = plot_header(cl, ha, 'location', 'north');

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'location'};
dflts = {'east'};
args = parse_args(pnames, dflts, varargin{:});

valid_location = {'east', 'west', 'north', 'south'};

assert(iscell(cl), 'CL should be a cell array');
assert(ishandle(ph), 'PH should be a handle');
assert(isvalidstr(args.location, valid_location),...
    'location %s is invalid', args.location);

[ns, nc] = size(cl);

%% make axes
ah = mk_axes(ph, args.location, nc);
ishoriz = any(strcmpi(args.location, {'north', 'south'}));
%% get classes
nl = cell(nc, 1);
cn = cell(nc, 1);
for ii=1:nc
    [cn{ii}, nl{ii}] = getcls(cl(:, ii));
end
%%
col = get_colors(cn);

for ii=1:nc
%     col = get_palette(length(cn{ii}));
    mk_header(ah(ii), cn{ii}, nl{ii}, col{ii}, ishoriz)
end



% sample labels
% text((0:nsample-1)+0.5,ones(nsample,1)*0.65,cl,'rotation',90,'color','c','fontweight','bold','fontsize',10,'horizontalalignment','left');

%class labels
% text([0;edg] + v*0.5, ones(nclass,1),cn,'color','y','fontweight','bold','fontsize',14,'horizontalalignment','center');

%rotated class labels
% text([0;edg(1:end-1)] + v*0.5, ones(nb,1)*0.65, texify(cn(nl(edg))),...
%     'rotation', 90, 'color', 'w', 'fontweight', 'bold',...
%     'fontsize', 10, 'horizontalalignment', 'left');

axes(ph);
end

function mk_header(ah, cn, nl, col, ishoriz)
%% create header
% axes(ah);
[edg, v] = class_edg(nl);
nclass = length(cn);

if ishoriz
    plotter = @barh;
    lim_field = 'ylim';
else
    plotter = @bar;
    lim_field = 'xlim';
end
%to fix quirk in matlab which refuses to plot single stacked bars
bh = plotter(ah, [v nan(size(v))]', 1, 'stacked');
axis(ah, 'tight', 'off');
set(ah, 'xtick', [], 'ytick', [], lim_field, [0.6,1.4]);
% set(ah, 'plotboxaspectratiomode', dam,'plotboxaspectratio', dar);

% col = get_palette(nclass);
nb = length(bh);
for ii=1:nb
    nlidx = nl(edg(ii));
    cmenu(ii)=uicontextmenu;
    set(bh(ii),'uicontextmenu',cmenu(ii),...
        'facecolor', col(nlidx,:), 'edgecolor', 'none');
    item(ii)=uimenu(cmenu(ii),'label',cn{nlidx});
end

end

function col = get_colors(cn)
csz = cumsum(cellfun(@length, cn));
allcol = get_palette(csz(end), 'scheme', 'motley20');
nc =length(cn);
col = cell(nc, 1);
st = 1;
for ii=1:length(cn)
    stp = st + length(cn{ii}) - 1;
    col{ii} = allcol(st:stp,:);
    st = stp + 1;
end

end

function ah = mk_axes(ph, location, n)
pos = get(ph, 'position');
% dam = get(ph, 'plotboxaspectratiomode');
% dar = get(ph, 'plotboxaspectratio');
ah = zeros(n, 1);
for ii=1:n
    switch lower(location)
        case 'east'
            wd = 0.9*(1-(pos(1)+pos(3)))/n;
            lt = pos(1) + pos(3) + (ii-1) * wd;
            bt = pos(2);
            ht = pos(4);
        case 'north'
            wd = pos(3);
            ht = 0.9*(1-(pos(2)+pos(4)))/n;
            lt = pos(1);
            bt = pos(2) + pos(4) + (ii-1)*ht;
        case 'south'
            wd = pos(3);
            ht = 0.9*(1-(pos(2)+pos(4)))/n;
            lt = pos(1);
            bt = pos(2) - ii*ht;
        case 'west'
            wd = 0.9*(1-(pos(1)+pos(3)))/n;
            lt = pos(1) - ii*wd;
            bt = pos(2);
            ht = pos(4);
        otherwise
            error('Invalid location %s', location);
    end
    ah(ii) = axes('position', [lt, bt, wd, ht]);    
end
end
