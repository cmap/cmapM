function res = runGeneMod(varargin)
% given a gene
% extract a row from the modz matrix
% append annotations
% create a pert x 
% apply sig filters

[args, help_flag] = get_args(varargin{:});

if ~help_flag
    
    res.args = args;
    zs = parse_gctx(args.ds, 'rid', args.rid, 'cid', args.cid);
    
    % annotate features
    if ~isempty(args.row_meta)
        zs = annotate_ds(zs, args.row_meta, 'dim', 'row',...
            'keyfield', 'pr_id', 'append', false);    
    end
    
    if ~isempty(args.col_meta)
        % annotate signatures
        zs = annotate_ds(zs, args.col_meta, 'keyfield', 'sig_id',...
            'dim', 'column', 'append', false);        
    end
    
    % Aggregate columns (signatures) by pert_id and cell_id
    res.aggzs = mortar.compute.GeneMod.aggregateZScore(zs,...
                                                  args.group_by);

    res.mod = mortar.compute.GeneMod.getGeneModByCell(res.aggzs);
    res.topmod = mortar.compute.GeneMod.getTopMod(res.mod, args.topn);
    
    res.zs = zs;
    
%     % save data
%     mkgctx(fullfile(out_folder, 'genemod.gctx'), gmds);
%     mkgctx(fullfile(out_folder, 'genemod_dn.gctx'), gm_down);
%     mkgctx(fullfile(out_folder, 'genemod_up.gctx'), gm_up);
%     
%     % make heatmaps
%     gene_sym = ds_get_meta(modz, 'column', 'pr_gene_symbol');
%     plot_heatmap(gm_down, sprintf('%s DOWN modulators', gene_sym{1}), 'genemod_dn');
%     plot_heatmap(gm_up, sprintf('%s UP modulators', gene_sym{1}), 'genemod_up');
%     savefigures('out', out_folder, 'mkdir', false, 'closefig', true);
end
end

function [args, help_flag] = get_args(varargin)

ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'run Gene modulator analysis', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    args.group_by = tokenize(args.group_by, ',');
end

end