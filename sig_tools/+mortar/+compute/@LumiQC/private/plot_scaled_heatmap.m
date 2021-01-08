function plot_scaled_heatmap(level_data, labels, platename, figure_name, varargin)
% plot_level_heatmap   generate the standard heat map of the fluorescent level of the wells in a plate

% $Author: David Lahr [dlahr@broadinstitute.org]
% $Date: Apr.29.2015
pnames = {'title'};
dflts =  {''};

arg = parse_args(pnames, dflts,varargin{:});


stat = describe(level_data);
t = sprintf('%s \n %s median: %2.0f cv: %2.0f%%', arg.title, platename, stat.median, stat.cv);
plot_platemap(level_data, labels, 'title', t, ...
    'showfig', false, 'name', figure_name);
caxis ([0 2.5])
end