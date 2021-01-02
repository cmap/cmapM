function plot_baseline_analyte_pair(varargin)
%Scatter plot displaying the relationship between the baseline expression
%levels for all analyte pairs in a specified cell line.
%
%Usage
%   plot_baseline_analyte_pair('MCF7')

config = struct('name', {'cell_id';...
                         '--ds';...
                         '--save_plot';...
                         '--out';...
                         '--filename'},...
    'default', {'';'/cmap/data/vdb/dactyloscopy/cline_affx_n1515x22268.gctx'; false; ''; ''},...
    'help', {'Cell line of interest (Required)';...
            'Baseline Expression dataset';...
            '';...
            '';...
            ''});
opt = struct('prog', mfilename, 'desc', 'Make baseline expression scatter');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

%Get and annotate baseline data
lm = mortar.common.Spaces.probe('lm').asCell;
ds = parse_gctx(args.ds,...
    'cid',args.cell_id,...
    'rid',lm,...
    'ignore_missing',true);
gene_annot = parse_record('/cmap/data/vdb/chip/L1000_EPSILON.R2.chip');
idx = strcmp('LM',{gene_annot.pr_type});
gene_annot = gene_annot(idx);
ds = annotate_ds(ds,gene_annot,...
    'dim','row',...
    'keyfield','pr_id');

%jn 11/14/2016 temp hack
if ~any(strcmp(args.cell_id,ds.cid))
    return
end

%Separate into dp52 and dp53 probes
all_analytes = gen_labels(500,'-prefix','Analyte ','-zeropad',false);
duo_analytes = all_analytes([12:498 500]);
data52 = ds_subset(ds,'row','pr_bset_id',{'dp52'});
data53 = ds_subset(ds,'row','pr_bset_id',{'dp53'});
data52 = ds_subset(data52,'row','pr_analyte_id',duo_analytes);
data53 = ds_subset(data53,'row','pr_analyte_id',duo_analytes);

%Make sure analytes are ordered correctly
[~,locb52] = sort(cell2mat(data52.rdesc(:,data52.rdict('pr_analyte_num'))));
[~,locb53] = sort(cell2mat(data53.rdesc(:,data53.rdict('pr_analyte_num'))));
data52 = ds_order(data52, 'column', locb52);
data53 = ds_order(data53, 'column', locb53);
assert(isequal(...
    data52.rdesc(:,data52.rdict('pr_analyte_id')),...
    data53.rdesc(:,data52.rdict('pr_analyte_id'))),...
    'Analytes not ordered the same');

%plot
f = figure;
scatter(data52.mat,data53.mat)
hold on
ax = gca;
plot(ax.XLim,ax.YLim,':r')
xlabel('dp52')
ylabel('dp53')
grid on
title([args.cell_id ' - Baseline Expression Analyte Scatter'])
    
if args.save_plot
    saveas(f,fullfile(args.out,args.filename),'png');
    clf;
end
end

