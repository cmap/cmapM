function plot_TAS_from_siginfo(varargin)
% plot_TAS_from_siginfo(varargin)
%
% This script is useful for seeding density plates. 
%
TAS_ID = 'distil_tas';
DOSE_ID = 'pert_dose';
CELL_ID = 'cell_id';
PERT_FIELD = 'pert_type';
TIME_PT = 'pert_time';
SEED_DENSITY = 'x_density';
FIELDS = {CELL_ID, PERT_FIELD, TIME_PT, SEED_DENSITY};
ANGLE_X_THRESHOLD = 3;

pnames = {'siginfo', 'x_variable', ...
    'groupby_field',...
    'PlotTitle', 'save_plot', 'save_fig', ...
     'out', 'annot_field','num_decimals','show_figure'};

dflts = {'', {DOSE_ID},...
        '',...
        '', false, false, ...
        pwd, FIELDS, 3, false};

args = parse_args(pnames, dflts, varargin{:});

if ~isstruct(args.siginfo)
    if isfileexist(args.siginfo)
        args.siginfo = parse_record(args.siginfo);
    else
       error(['Invalid input record. Must be either nx1 struct ' ... 
                'or path to table file.'] )
    end
end

ndecimals = args.num_decimals;
siginfo_table = args.siginfo;

if ~iscell(args.groupby_field)
    groupby = {args.groupby_field};
else
    groupby = args.groupby_field;
end

%If multiple are given only the first is used
if iscell(args.x_variable)
    x_variable = args.x_variable{1};
else
    x_variable = args.x_variable;
end

is_xvar_str = iscellstr({siginfo_table.(x_variable)});
if (is_xvar_str)
    x_axis_vals = unique({siginfo_table.(x_variable)});
else
    x_axis_vals = unique([siginfo_table.(x_variable)]);    
end

FIELDS = mortar.compute.Calib.validate_parameters(siginfo_table, args.annot_field, 0);

field_vals = cell(1,length(FIELDS));
for i = 1:length(FIELDS)
    is_field_str = iscellstr({siginfo_table.(FIELDS{i})});
    if (is_field_str)
        field_vals{i} = unique({siginfo_table.(FIELDS{i})});
    else
        field_vals{i} = num2str(unique([siginfo_table.(FIELDS{i})]));
    end
end

str = cell(1, length(FIELDS));
%%Get information about siginfo table for annotations
for i = 1:length(FIELDS)
    if iscellstr(field_vals{i})
        str{i} = sprintf('%s: %s ', FIELDS{i}, strjoin(field_vals{i}));
    else
        str{i} = sprintf('%s: %s ', FIELDS{i}, strtrim(char(field_vals(i))'));
    end
end
% dosetxt = sprintf('Doses: %s', char(field_vals{2})');
% typetxt = sprintf('Pert Types:%s ', char(field_vals{3})');
% timetxt = sprintf('Time Points: %s', char(field_vals{4})');
% densitytxt = sprintf('Seeding Densities: %s', char(field_vals{5})');
% str = {celltxt, dosetxt, typetxt, timetxt, densitytxt};

dim = [0.7 0.82 0.2 0.1];
dim_legend = [0.77 0.82 0.2 0.1];
font_size = 8;
text_alignment = 'right';

%% Plot 
if isempty(groupby{1})
    naxis = length(x_axis_vals);
    
    %get longest array length
    num_points = 0;
    for i=1:naxis
        if (is_xvar_str)     
            temp_length = sum(strcmp(x_axis_vals(i), ...
                {siginfo_table.(x_variable)}));
        else
            temp_length = sum(x_axis_vals(i)==[siginfo_table.(x_variable)]);
        end
        num_points = max(num_points, temp_length);
    end
    
    n_vals = NaN(1,naxis);
    group_plot_data = NaN(num_points, naxis);
    for ii = 1:length(x_axis_vals)
        if (is_xvar_str) 
            idx = strcmp(x_axis_vals(ii), ...
                {siginfo_table.(x_variable)});
        else
            idx = x_axis_vals(ii)==[siginfo_table.(x_variable)];
        end
        ln = sum(idx);
        group_plot_data(1:ln,ii) = [siginfo_table(idx).(TAS_ID)];
        n_vals(ii) = ln;
    end
    plot_data = {group_plot_data};
    
    color_map = get_palette(1);
    
    if args.show_figure
        figure
    else
        myfigure(false);    
    end
    
    aboxplot(plot_data,...
        'Colormap',color_map,...
        'OutlierMarkerSize',10)
  
    xlabel(x_variable,'Interpreter', 'None')
    if (~is_xvar_str)
        x_axis_vals = round(x_axis_vals, ndecimals);
    end
    
    if (~is_xvar_str)
        x_ticks = arrayfun(@(x) num2str(x), x_axis_vals, 'Uni', false);
    else
        x_ticks = x_axis_vals;
    end
    
    %Add n-values to x-labels
    for i=1:naxis
       x_ticks{i} = sprintf('%s (n=%d)', x_ticks{i}, n_vals(i)); 
    end
    
    set(gca,'XTickLabel',x_ticks, ...
            'TickLabelInterpreter', 'None');
    if length(x_axis_vals) > ANGLE_X_THRESHOLD
        set(gca, 'XTickLabelRotation',45, 'FontSize', 10)
    end
    ylabel(TAS_ID,'Interpreter', 'None')
    ylim([0 1]);
    if isempty(args.PlotTitle)
        plot_title = sprintf('TAS vs %s', x_variable);
    else
        plot_title = args.PlotTitle;
    end 
    title(plot_title, 'Interpreter', 'None');
    namefig(plot_title);
    
    annotation('textbox', dim, 'String', str, ...
        'FitBoxToText', 'off', 'Interpreter', 'None',...
        'FontSize', font_size, 'HorizontalAlignment', text_alignment, ...
        'EdgeColor', 'none');
    grid on
    fname = validvar(lower(strrep(plot_title,' ', '_')));
    namefig(gcf,fname{:});
    if args.save_plot   
        saveas(gcf,fullfile(args.out,fname{:}), 'png');
    end
    if args.save_fig   
        saveas(gcf,fullfile(args.out,fname{:}), 'fig');
    end
else
    num_fields = length(groupby);
    for ii=1:num_fields     %for each groupby_field header
        is_str = iscellstr({siginfo_table.(groupby{ii})});
        if (is_str)
            bins = unique({siginfo_table.(groupby{ii})});
        else
            bins = unique([siginfo_table.(groupby{ii})]);
        end
        num_bins = length(bins);
        plot_data = cell(1,num_bins);
        show_all_nvals = 0;
        n_vals = NaN(1, num_bins);
        for jj = 1:num_bins %for each group (group_field_value)
            is_str = iscellstr(bins);
            if (is_str)      
                sub_table = siginfo_table(strcmp(bins(jj), ...
                    {siginfo_table.(groupby{ii})}),:);
            else
                sub_table = siginfo_table(...
                    bins(jj)==[siginfo_table.(groupby{ii})],:);
            end   
            naxis = length(x_axis_vals);
            
            %get longest array length
            num_points = 0;
            for i=1:naxis
                if (is_xvar_str)     
                    temp_length = sum(strcmp(x_axis_vals(i), ...
                        {sub_table.(x_variable)}));
                else
                    temp_length = sum(x_axis_vals(i)==[sub_table.(x_variable)]);
                end
                num_points = max(num_points, temp_length);
            end
            
            %extract data from table
            group_plot_data = NaN(num_points, naxis);
            for kk = 1:length(x_axis_vals)
                if (is_xvar_str) 
                    idx = strcmp(x_axis_vals(kk), ...
                        {sub_table.(x_variable)});
                else
                    idx = x_axis_vals(kk)==[sub_table.(x_variable)];
                end
                ln = sum(idx);
                group_plot_data(1:ln,kk) = [sub_table(idx).(TAS_ID)];
                if isnan(n_vals(jj))
                    n_vals(jj) = ln;
                elseif (n_vals(jj) ~= ln)
                    show_all_nvals = 1;
                end
            end
            
            plot_data{jj} = group_plot_data;
        end
        
        color_map = get_palette(num_bins);
        
        if args.show_figure
            figure
        else
            myfigure(false);    
        end
        %title
        if isempty(args.PlotTitle)
            plot_title = sprintf('TAS vs %s by %s', x_variable, groupby{ii});
        else
            plot_title = args.PlotTitle;
        end
        title(plot_title, 'Interpreter', 'None');
        namefig(plot_title);
        
        %legend
        if (~is_str)
            legend_var = arrayfun(@(x) num2str(x), bins, 'Uni', false);
        else
            legend_var = bins;
        end
        
        %Add n_values
        if (~show_all_nvals)
            for i=1:num_bins
                legend_var{i} = sprintf('%s (n=%d)', legend_var{i}, n_vals(i));
            end
            aboxplot(plot_data,...
            'labels', x_axis_vals, ...
            'Colormap',color_map,...
            'OutlierMarkerSize',10)
        else
            aboxplot(plot_data,...
            'labels', x_axis_vals, ...
            'Colormap',color_map,...
            'OutlierMarkerSize',10,...
            'showallnvals', 1)
        end

        if (~is_xvar_str)
            x_axis_vals = round(x_axis_vals, ndecimals);
        end
        
        xlabel(x_variable,'Interpreter','None')
        set(gca,'XTickLabel',x_axis_vals, ...
            'TickLabelInterpreter', 'None');
        
        
        if length(x_axis_vals) > ANGLE_X_THRESHOLD
            set(gca, 'XTickLabelRotation',45, 'FontSize', 10);
        end
        
        ylabel(TAS_ID,'Interpreter','None');
        ylim([0 1]);

            %Hack to add a legend title
        %http://undocumentedmatlab.com/blog/plot-legend-title
        leg = legend(legend_var,...
            'location','eastoutside',...
            'Interpreter', 'None');
        text(...
            'Parent', leg.DecorationContainer, ...
            'String', groupby{ii}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'Position', [0.5, 1.05, 0], ...
            'Units', 'normalized',...
            'Interpreter', 'None');
        
        annotation('textbox', dim_legend, 'String', str, ...
        'FitBoxToText', 'off', 'Interpreter', 'None',...
        'FontSize', font_size, 'HorizontalAlignment', text_alignment, ...
        'EdgeColor', 'none');
        grid on
        
        fname = validvar(lower(strrep(plot_title,' ', '_')));
        namefig(gcf,fname{:});
        if args.save_plot   
            saveas(gcf,fullfile(args.out,fname{:}), 'png');
        end
        if args.save_fig   
            saveas(gcf,fullfile(args.out,fname{:}), 'fig');
        end
    end
end

end