function figh = plot_summly_raster(query_id, query_desc, summly_row)
% PLOT_SUMMLY_RASTER Generate Summly raster plot
% Parameters
% ----------
% query_id : str
%	The query id name (from the query_info.txt file)
% query_desc : str
%	The query description name (from query_info.txt file)
% summly_row : struct
%	A row of the summly table, from which to generate a raster plot

% Returns
% -------
% figh : Handle to the figure

% get info on the query
qstr = sprintf('{pert_id : "%s"}', query_id);
query_info = mongo_info('pert_info', qstr);
if length(query_info)
	query_type = query_info.pert_type;
else
	query_type = '';
end

% extract fields from the summly row
pert_id = summly_row.pert_id;
pert_iname = summly_row.pert_iname;
pert_type = summly_row.pert_type;
sum_rank_pt = str2double(tokenize(summly_row.norm_rankpt, '|'));
sum_cell_id = tokenize(summly_row.cell_id, '|');
best4_index = str2double(tokenize(summly_row.best4_index, '|'));
best6_index = str2double(tokenize(summly_row.best6_index, '|'));
y2ticklabel = num2cellstr(sum_rank_pt);

% generate title and name string for figure
if length(query_type)
	query_title = texify(sprintf('QUERY ID: %s (%s) [%s]', query_id,...
	                    query_desc, upper(query_type)));
else
	query_title = texify(sprintf('QUERY ID: %s (%s)', query_id,...
	                    query_desc));
end
summly_title = texify(sprintf('SUMMLY ID : %s (%s) [%s]', pert_id,...
                    pert_iname, upper(pert_type)));
title_str = [query_title, '\newline', summly_title];
clean_pin = validvar(pert_iname);
name_str = lower(sprintf('%s_%s_%s',...
    pert_type, clean_pin{1}, pert_id));

% generate figure
figh = myfigure(true);
hold on
[hrest, pobj] = plot_rank_raster(sum_rank_pt,...
                 sum_cell_id,...
                 'title', title_str, ...
                 'name', name_str, ...
                 'color', get_color('blue'),...
                 'linewidth', 2, 'y2ticklabel', y2ticklabel,...
                 'y2label', texify(pert_id));            
% save axes properties to restore later
ah = findobj(gcf, 'type', 'axes');
ax_prop = get(ah);

cell_id_lut = mortar.containers.Dict(pobj.ygp, pobj.y);
lh = [hrest];
leg_text = {'summary'};

% highlight top 6 connections
if isequal(length(best6_index), 6)
    y6 = cell_id_lut(sum_cell_id(best6_index));
    h6 = plot_raster(sum_rank_pt(best6_index),...
        y6,...
        'tick_gap', 0.2,...
        'ytick', ax_prop(1).YTick,...
        'color', get_color('ochre'),...
        'linewidth', 2, 'yticklabel', '');
    lh = [lh, h6];
    leg_text = [leg_text, {'top 6'}];
end

% highlight top 4 connections
if isequal(length(best4_index), 4)
    y4 = cell_id_lut(sum_cell_id(best4_index));
    h4 = plot_raster(sum_rank_pt(best4_index),...
        y4,...
        'tick_gap', 0.2,...
        'ytick', ax_prop(1).YTick,...
        'color', get_color('scarlet'),...
        'linewidth', 2, 'yticklabel', '');
    lh = [lh, h4];
    leg_text = [leg_text, {'top 4'}];
end

% Add legend. Right now, we're too cluttered to show it. Will require some 
% plotting tweaks to make this work.
% leg = legend(lh, leg_text,...
%             'location', 'northoutside',...
%             'orientation', 'horizontal',...
%             'box', 'off', 'fontsize', 10,...
%             'fontweight', 'normal');
% legend(leg, 'boxoff');

pos = get(ah(1),'position');
set(ah, 'position', pos, 'xlim', ax_prop(1).XLim,...
    'ylim', ax_prop(1).YLim, 'ytick', ax_prop(1).YTick,...
    'box', 'off');
