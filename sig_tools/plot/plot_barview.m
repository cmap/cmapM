function [fh, bh, ih, th] = plot_barview(x, varargin)
% PLOT_BARVIEW Generate CMAP barview plot.
%   PLOT_BARVIEW(X)
%   PLOT_BARVIEW(X, 'param1', 'value1', ...) Specify optional parameters.
%   Valid parameters are:
%   'facecolor' : cell array of strings, colors for positive, null
%       and negative scores. Default is {'peach', 'w', 'mint'}.
%   'instance_text' : cell array of strings, instance labels for each
%       query. Default is none.
%   'mark_index' : cell array of indices, row indices in X to highlight.
%       Default is none.
%   'name' : char, figure name.
%   'rid' : cell array of strings, labels for each row in X. Default is
%       none.
%   'showfig' : boolean, 
%   'show_rank' : boolean
%   'sort_order' : char, Sort ordering of values in X. 
%                  Options are {'ascend', 'descend'}. Default is 'descend'
%   'title' : char, plot title
%   'columnlabel' : cell array of strings, labels for each column in X
%   'ylabelrt' : char, label place on the right yaxis
%
% Example:
%   x=randn(384, 5);
%   x(abs(x)<1) = 0;
%   rid = gen_labels(384);   
%   qlabel = {'Q1', 'Q2', 'Q3', 'Q4', 'Q5'};
%   mark_index = {[10,40], 300, 5, [1, 25, 35], 100};
%   label_rt = 'Barview results';
%   ilabel = {'I1', 'I2', 'I3', 'I4', 'I5'};
%   fh = plot_barview(x, 'mark_index', mark_index,...
%         'columnlabel', qlabel, 'rid', rid, 'title', 'Barview',...
%         'show_rank',true, 'ylabelrt', label_rt,...
%         'instance_text', ilabel);
%     

pname = {'mark_index','facecolor', 'sort_order',...
    'columnlabel', 'rid', 'title',...
    'show_rank', 'ylabelrt', 'showfig',...
    'name', 'instance_text'};
dflts = {'', {'peach','w','mint'}, 'descend',...
    '', '', '',...
    true, '', true,...
    '', ''};
args  = parse_args(pname, dflts, varargin{:});

[nr, nc] = size(x);
counts = [sum(x<0); sum(abs(x)<eps); sum(x>0)]';
if isequal(nc,1)
    is_single=true;
    counts = [counts; nan(1, 3)];
else
    is_single = false;
end

fh = myfigure(args.showfig);
bh = bar(counts, 'stacked','barwidth',0.4);
axis tight
grid off
ylim ([-10, nr+10])
set(gca, 'ytick', [0,nr], 'yticklabel', num2cellstr([nr, 1]),...
    'tickdir','out');
baseh = get(bh,'baseline');
set(baseh{1}, 'linestyle', 'none');
set(baseh{2}, 'color', get_color('grey'));
box off
title(args.title);

[axr, axl] = ylabelrt(texify(args.ylabelrt), 'color', 'b','fontsize',8);
box(axr, 'off');

% x positions for each bar
bw = get(bh(1), 'BarWidth');
x_start = (1:nc) - 0.5*bw;
x_stop = (1:nc) + 0.5*bw;

if is_single
    xl = get(gca,'xlim');
    xlim([xl(1), x_stop(1)]);
end

if ~isempty(args.columnlabel)
    set(gca, 'xtick', 1:nc, 'xticklabel', args.columnlabel, 'fontsize', 8);
    rotateticklabel(gca, 45);
end
ylabel('Rank')
for ii=1:3
    set(bh(ii), 'facecolor', get_color(args.facecolor{ii}),...
        'edgecolor', get_color('grey'));
end

ih = [];
th = [];

if ~isempty(args.mark_index)           
    assert(iscell(args.mark_index), 'mark index must be a cell array');        
    nm = size(args.mark_index, 2);
    assert(isequal(nm, nc), 'length of mark_index must match columns in x');
    
    rnk = rankorder(x, 'fixties', false, 'direc', args.sort_order);

    delta = (x_stop(1)-x_start(1))/10;    
    hold on
    ih = zeros(nc, 1);
    th = cell(nc, 1);
    for ii=1:nc
        y = rnk(args.mark_index{ii}, ii);        
        rev_rnk = nr - y + 1;
        ny = length(y);
        xx = nan(3*ny,1);
        yy = xx;
        yy(1:3:3*ny) = rev_rnk;
        yy(2:3:3*ny) = rev_rnk;
        xx(1:3:3*ny) = x_start(ii);
        xx(2:3:3*ny) = x_stop(ii);
        ih(ii) = plot(xx, yy, 'color', get_color('scarlet'), 'linewidth', 2);
        
        if args.show_rank
            inst_lbl = num2cellstr(y);
            if ~isempty(args.rid)
%                 inst_lbl = strcat(inst_lbl, '(', args.rid(args.mark_index{ii}), ')');
                inst_lbl = args.rid(args.mark_index{ii});
            end
            
            th{ii} = text(repmat(x_stop(ii)+delta, ny, 1), rev_rnk-2, inst_lbl,...
                'color', get_color('blue'),...
                'verticalalignment', 'middle',...
                'fontweight', 'bold',...
                'fontsize', 8);
        end
        if ~isempty(args.instance_text)
            text(x_start(ii)-(x_stop(ii)-x_start(ii))/2, nr*0.01,...
                args.instance_text{ii}, 'rotation', 90,...
                'fontsize', 7, 'color', get_color('grey'))
        end
    end
end
if ~isempty(args.name)
    namefig(texify(args.name));
end
end
