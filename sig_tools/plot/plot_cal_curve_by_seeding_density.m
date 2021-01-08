function plot_cal_curve_by_seeding_density(varargin)
% plot_cal_curve_by_seeding_density(varargin)
%
% This script is useful for seeding density plates. It plots the
% calibration curves for the invariant set genes as a grouped box-plot
% where the groups are defined by the invariant sets and each box-plot
% within a group corresponds to a different seeding density
%
%Example use
%   plot_cal_curve_by_seeding_density('DIVR.BASE003_NCIH522_24H_X1.A2_B29',...
%        'DIVR',...
%        'seeding_density_field','x_seeding_density')

config = struct('name', {'roast_plate';...
                         'cohort';...
                         '--pod_dir';...
                         '--seeding_density_field';...
                         '--save_plot';...
                         '--out';...
                         '--filename'},...
    'default', {'';'';'/cmap/obelix/pod/custom'; 'x_seeding_density'; false; '.'; ''},...
    'help', {'';...
            '';...
            'Root directory for lxb and map files';...
            'Seeding density field';...
            'Whether to save plots (Logical)';...
            'plot output directory';...
            'filename to save plot to';});
opt = struct('prog', mfilename, 'desc', 'Plot calibration curve for seeding density plate');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

%% Load the csv file and the platemap
fullfile(args.pod_dir,args.cohort,'lxb',args.roast_plate,[args.roast_plate '.csv'])
ds = parse_csv(fullfile(args.pod_dir,args.cohort,'lxb',args.roast_plate,[args.roast_plate '.csv']));
plate_map = parse_record(fullfile(args.pod_dir,args.cohort,'maps',[args.roast_plate '.map']));

%% Set up the MFI data set
inv_set = gen_labels(10,...
    '-prefix','Analyte ',...
    '-zeropad',false);
ds = ds_slice(ds,'rid',inv_set);

well_id = get_well_id_from_csv_id(ds.cid);
ds.cid = well_id;
ds = ds_slice(ds,'cid',{plate_map.rna_well});
ds = annotate_ds(ds,plate_map,...
    'dim','column',...
    'keyfield','rna_well',...
    'skipmissing',true);

%% Form the array of matrices to be passed into aboxplot
%mfi{ii} should be the matrix of inv_set analytes x samples corresponding
%to seeding density ii
usd = unique([plate_map.(args.seeding_density_field)]);
for ii = 1:length(usd)
    idx = [plate_map.(args.seeding_density_field)] == usd(ii);
    these_wells = {plate_map(idx).rna_well};
    this_mfi = ds_slice(ds,'cid',these_wells);
    mfi{ii} = this_mfi.mat';
end

%color map must have same number of rows as number of seeding densities
%somewhat hacky: Make a colormap that supports up to 40 colors, then prune
%to the number that are actually needed
big_color_map = [1,0,0;...
    .9,.9,0;...
    0,1,0;...
    0,1,1;...
    0,0,1;...
    1,0,1;...
    .7,.7,.7;...
    .3,.3,.3];
big_color_map = repmat(big_color_map,5,1); 
color_map = big_color_map(1:length(usd),:);

legend_var = arrayfun(@(x) num2str(x), usd, 'Uni', false);

%% Plot
aboxplot(mfi,...
    'Colormap',color_map,...
    'OutlierMarkerSize',10)

xlabel('Invariant Set')
ylabel('MFI')
title(args.roast_plate,'Interpreter','None')
grid on

%Hack to add a legend title
%http://undocumentedmatlab.com/blog/plot-legend-title
leg = legend(legend_var,'location','eastoutside');
text(...
    'Parent', leg.DecorationContainer, ...
    'String', 'Seeding density', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', ...
    'Position', [0.5, 1.05, 0], ...
    'Units', 'normalized');


if args.save_plot
    saveas(gcf,fullfile(args.out,args.filename),'png')
    clf;
end

end

function well_ids = get_well_id_from_csv_id(csv_ids)
% Go from '1(1,A1)' to 'A1'

for ii = 1:length(csv_ids)
    t = csv_ids{ii};
    temp = strsplit(t, {',',')'});
    temp = temp{2};
    if length(temp) == 2
        temp = [temp(1) '0' temp(2)];
    end
    well_ids{ii} = temp;
    
end

end