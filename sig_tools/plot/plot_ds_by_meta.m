function plot_ds_by_meta(varargin)
%Make plots summarazing a given quantity of a dataset's column metadata
%
%Example:
%
%plot_ds_by_meta(ds,...
%   'separate_plot_field','pert_iname',...
%   'x_axis_field','x_seeding_density',...
%   'y_axis_field','distil_cc_q75')
%
%will make separate seeding_density vs cc_q75 plots per compound.

config = struct('name', {'ds';...
                         '--separate_plot_field';...
                         '--x_axis_field';...
                         '--y_axis_field';...
                         '--suptitle';...
                         '--save_plot';...
                         '--out';...
                         '--filename'},...
    'default', {'';''; ''; ''; ''; false; '.'; ''},...
    'help', {'Dataset with metadata of interest';...
            'Column header for which to make separate plots for';...
            'Column header containing x-axis data';...
            'Column header containing y-axis data';...
            'Super title for figure';...
            '';...
            '';...
            ''});
opt = struct('prog', mfilename, 'desc', 'Plot metadata from a ds');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

ds = args.ds;

ufield = unique(ds.cdesc(:,ds.cdict(args.separate_plot_field)));

f = figure;
for ii = 1:length(ufield)
    [a,b] = balance_partition(length(ufield));
    subplot(a,b,ii);
    
    idx = strcmp(ufield(ii),ds.cdesc(:,ds.cdict(args.separate_plot_field)));
    xfield = cell2mat(ds.cdesc(idx,ds.cdict(args.x_axis_field)));
    yfield = cell2mat(ds.cdesc(idx,ds.cdict(args.y_axis_field)));
    
    [~,sort_idx] = sort(xfield);
    xfield = xfield(sort_idx);
    yfield = yfield(sort_idx);
    
    plot(xfield,yfield,'O-');

    ax = gca;
    ax.YLim = [0 1];
    ax.XTick = xfield;
    ax.XTickLabelRotation = 45;
    ax.YTick = 0:.2:1;
    ax.FontSize = 5;
    grid on
    title(ufield{ii})
    xlabel(args.x_axis_field,'Interpreter','None')
    ylabel(args.y_axis_field,'Interpreter','None')
end

%make super title
[~,h] = suplabel(args.suptitle,'t');
set(h,'FontSize',10)
set(h,'Interpreter','none')

if args.save_plot
    saveas(f,fullfile(args.out,args.filename),'png');
    clf;
end
end

