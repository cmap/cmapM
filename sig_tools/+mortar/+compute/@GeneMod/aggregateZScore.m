function aggzs = aggregateZScore(zs, gp_var)
% AGGREGATEZSCORE Aggregate z-score columns (signatures) by specified
% grouping variable(s).
%   AGGZS = aggregateZScore(ZS, GPVAR) Aggregates columns of MODZ grouped
%   by the fields specified by GPVAR. The max quantile is used as the
%   summarization metric with [33, 67] being the low and high quantiles
%   respectively. ZS is an annotated z-score dataset. GPVAR is a cell
%   array of column fields to group on eg: {'pert_id', 'cell_id'}. The
%   result is a aggregated z-score dataset AGGZS with the number of columns
%   equalling the number of groups specified by GPVAR and the same rows as
%   ZS

    zs = parse_gctx(zs);
    
%     % annotate features
%     modz = annotate_ds(modz, gene_info(modz.rid), 'keyfield', 'pr_id', 'dim', 'row', 'append', false);
    
%     if ~isempty(args.col_meta)
%         % annotate signatures
%         modz = annotate_ds(modz, args.col_meta, 'keyfield', 'sig_id', 'dim', 'column', 'append', false);        
%     end
%     
    assert(all(ismember(gp_var, zs.chd)), 'Grouping fields not found');
    
    
    aggzs = mortar.compute.Gutc.aggregateQuery(zs,...
                                                  [],...
                                                  gp_var,...
                                                  2,...
                                                  'maxq',...
                                                  struct('q_low', 33,...
                                                         'q_high', 67));
                                                     
   [~, cidx] = sort(aggzs.cid);
   aggzs = ds_slice(aggzs, 'cidx', cidx);
   
end