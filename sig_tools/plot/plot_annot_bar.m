function [bh, th] = plot_annot_bar(varargin)

pnames = {'annot_label', 'annot_color', 'annot_size',...
    'annot_background', 'annot_precision', 'as_percent'};
dflts = {'', 'k', 10, ...
    'none', inf, false};

% find first string argument
[reg, pvpairs] = parseparams(varargin);
% values to plot
[msg, x, y] = xychk(reg{:}, 'plot');
assert(isempty(msg), sprintf('%s: Invalid input', mfilename))

% extract annotbar specific params
[local_args, ext_args] = get_local_params(pvpairs, pnames);
args = parse_args(pnames, dflts, local_args{:});

% plot the bar chart
bh = bar (x,y, ext_args{:});
hold on

% Add labels
if isempty(args.annot_label)
    % Use Y values as labels
    if args.as_percent
        args.annot_label = strcat(num2cellstr(100*y/sum(y), 'precision', args.annot_precision),'%');
    else    
        args.annot_label = num2cellstr(y, 'precision', args.annot_precision);
    end
end

th = text(double(x), double(y), args.annot_label, ...
    'color', args.annot_color, 'FontSize', args.annot_size,...
    'fontweight', 'bold', 'backgroundcolor', args.annot_background,...
    'horizontalalignment', 'center',...
    'verticalalignment', 'bottom');

end
