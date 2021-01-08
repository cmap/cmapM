classdef DiffConn
    % Methods to compute differential connectivities
    % public properties
    properties (Constant=true)

    end

    methods (Static=true)
        % Compute differential connectivity metrics
        rpt = diffConnMetrics(ds, pheno_field);
        % 
        ds_filt = filterResults(ds, ps_th, min_rows_to_pass);
        
        runDiffConn(ps, pheno, row_meta, out_path);
        
        rpt = compareClassSimilarity(ds_sim, tbl,...
                cid_field, group_field, class_field, pos_class);        

        ds_filt = filterBestConnections(ds, row_metric_field, ps_th, min_rows_to_pass);
        
        gain = computeGain(pos_score, neg_score);
        gain = computeGainStratified(pos_score, neg_score, ps_th);
        [row_meta, h] = plotGainVsSelectivity(ds, sel_rpt);
        [row_meta, h] = plotGainStratifiedVsSelectivity(ds, sel_rpt);
        
        runDiffConnPermutation(ps, pheno, nperm, row_meta, out_path);
        
        res = calcEmpiricalPval(obs_a, obs_b, pop_a, pop_b, id_obs,...
                                   id_pop_a, id_pop_b, varargin);
                               
                               
        % Introspect functions
        [cc, srt_ord, gp_vec] = corrMatrixToGroup(mat, gp_idx, agg_fun, corr_metric);
        subsets = splitIntrospect(varargin);
        %subsets = subsetIntrospect(cs, cs_col_meta, pert_info, cp_sensitivity, moa_sensitivity);
        cs = reorderIntrospect(varargin);
        [ofname, status, result] = makeIntrospectHeatmap(varargin);
        res = batchReorderIntrospect(varargin);
        
        % Run Summly
        runSummlyConn(ps, maxq_lo, maxq_hi, col_meta, row_meta, out_path);
    end

end