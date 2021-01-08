function [h, ax, bigax, p, ccrt] = plot_pwcorr(x, varargin)
pnames = {'title', 'clabel', 'metric',...
    'xlabel','ylabel', 'clabel_len',...
    'histcolor','clabel_location','setbg',...
    'showfig', 'name'};
dflts = {'', '', 'pearson',...
    '', '', 12,...
    'c', 'edge',false,...
    true, ''};
args = parse_args(pnames, dflts, varargin{:});

cc = fastcorr(x, 'type', args.metric);

hf = myfigure(args.showfig);
[h,ax,bigax,p]=plotmatrix(x);
n = size(x, 2);

%histogram color
for ii=1:n      
    set(p(ii), 'facecolor', args.histcolor);
end

[ir, ic] = find(tril(true(n), -1));
lt = sub2ind(size(cc), ir, ic);
rt = sub2ind(size(cc), ic, ir);
axlt = ax(lt);
axrt = ax(rt);
hrt = h(rt);
cclt = cc(lt);
ccrt = cc(rt);
% fsz = round(12 + (abs(cclt).^2)*21);
fsz = 12 + 10*sigmoid(abs(cclt),-1,0.3,0.05);
if args.setbg
    bgmap = gray(64);
    bgcol_lt = round(((cclt + 1)*(size(bgmap, 1)-1)/2)+1);
    bgcol_rt = round(((ccrt + 1)*(size(bgmap, 1)-1)/2)+1);
end
% metric values in the lower triangle
% set bkg color of cells
for ii=1:length(axlt)
    set(hf, 'CurrentAxes', axlt(ii));
    xl=get(gca,'xlim');
    yl=get(gca,'ylim');
    %turn off lower triangle
    cla(axlt(ii));
    xlim(xl)
    ylim(yl)
    if args.setbg
        set(axlt(ii), 'color', bgmap(bgcol_lt(ii),:));
        set(axrt(ii), 'color', bgmap(bgcol_rt(ii),:));
    end
    
    mx = mean(xl);
    my = mean(yl);
    th = text(mx, my, sprintf('%1.2f', cclt(ii)));
    if cclt(ii)>=0
        fcol = 'k';
    else
        fcol = 'r';
    end
    set(th, 'horizontalalignment', 'center',...
        'fontweight','bold','color',fcol, 'fontsize', fsz(ii));
    set(hrt(ii), 'color', fcol)
end

% column names
if isequal(length(args.clabel), n)
    s = strtrunc(args.clabel, args.clabel_len);
    if isequal(args.clabel_location, 'diagonal')
        set(p, 'visible', 'off');
        for ii=1:n
            thisax = ax(ii,ii);
            axes(thisax);
            xl = get(thisax,'xlim');
            yl = get(thisax,'ylim');
            cla
            %set(thisax, 'color',ones(3,1)*0.86)
            text(mean(xl),mean(yl), s{ii},'horizontalalignment','center','fontweight','bold','fontsize',10,'color','b');            
        end
    else
        for ii=1:n
            set(ax(ii, n), 'yaxislocation','right')
            ylh = ylabel(ax(ii, n), texify(s{ii}));
            set(ylh, 'fontsize', 10)
            xlh = title(ax(1, ii), texify(s{ii}));
            set(xlh, 'fontsize', 10, 'verticalalignment', 'cap')
        end
    end
end

% figure title
if ~isempty(args.title)
    p = mtit(bigax, texify(args.title));
    set(p.th, 'color', 'b', 'verticalalignment', 'bottom', 'fontsize', 12)
end

% figure ylabel
if ~isempty(args.ylabel)
    yh = ylabel(bigax, texify(args.ylabel), 'color', 'b');    
end

% figure xlabel
if ~isempty(args.xlabel)
    xh = xlabel(bigax, texify(args.xlabel), 'color', 'b');
end

% figure name
if ~isempty(args.name)
    namefig(args.name);
end
   
end

