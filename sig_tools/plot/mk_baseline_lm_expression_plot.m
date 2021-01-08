function mk_baseline_lm_expression_plot(varargin)
%Plots a cdf of landmark expression for a given cell line and a set of
%reference cell lines. Useful to make sure enough landmark genes are
%expressed in a cell line.
%
%Usage
%     mk_baseline_lm_expression_plot('MCF7',...
%           'cell_id_ref','/cmap/data/vdb/spaces/lincs_core_lines.grp')  

config = struct('name', {'cell_id';...
                         '--cell_id_ref';...
                         '--baseline_ds';...
                         '--save_plot';...
                         '--out';...
                         '--filename'},...
    'default', {'';'/cmap/data/vdb/spaces/lincs_core_lines.grp'; '/cmap/data/vdb/dactyloscopy/cline_affx_n1515x22268.gctx'; false; '.'; ''},...
    'help', {'Cell line of interest (Required)';...
            'cell array or .grp file containig eference cell lines';...
            'Baseline expression dataset';...
            'Whether to save plot (Logical)';...
            'plot output directory';...
            'filename to save plot to';});
        
opt = struct('prog', mfilename, 'desc', 'Plot cdf of landmark expression');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

if ~iscell(args.cell_id_ref)
    args.cell_id_ref = parse_grp(args.cell_id_ref);
end

lm = mortar.common.Spaces.probe('lm');
lm = asCell(lm);
ds = parse_gctx(args.baseline_ds,...
    'rid',lm,...
    'cid',vertcat(args.cell_id,args.cell_id_ref),...
    'ignore_missing',true);

f = figure;
for ii = 1:length(ds.cid)
    [F,X] = ecdf(ds.mat(:,ii));
    
    if strcmp(ds.cid(ii),args.cell_id)
        h(ii) = plot(X,F,'-r',...
                    'DisplayName',ds.cid{ii},...
                    'LineWidth',3);
    else
        h(ii) = plot(X,F,'-k','DisplayName','Reference');
    end
    
    hold on
end

xlabel('Expression')
ylabel('cdf')
legend(h(1:2))
grid on
title('CDF of landmark expression')

if args.save_plot
    saveas(f,fullfile(args.out,args.filename),'png')
    clf;
end

end