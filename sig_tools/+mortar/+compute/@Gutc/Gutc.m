classdef Gutc
% Algorithms to compute connectivity between signatures.

    methods(Static=true)

       %==GUT-C algorithms        
        % Normalize raw connectivity scores with touchstone signatures
        [ns, rpt] = normalizeQuery(cs, ts);
        
        % Normalize raw connectivity scores using a subset of signatures
        % as reference
        [ncs, rpt, pos_mean, neg_mean] = normalizeQueryRef(cs, rid_ref, varargin);

        % Normalize raw connectivity scores with touchstone signatures
        % including out of bag (non-TS) signatures
        [ns, rpt, pos_mean, neg_mean] = normalizeQueryOOB(cs, ts);
        
        % 
        [ncs, rpt, pos_mean, neg_mean] = normalizeQueryRefGrouped(cs, rid_ref, gp_field);
        
        % Compute null distributions using size-matched set permutations
        [nes_obs_ds, qval_ds] = normalizeQueryWithPermutedNull(es_ds, score_ds, rank_ds, set_sizes, varargin);
        [set_size_forperm, set_size_gpidx] = discretizeSetSizes(set_sizes, num_freq_sets, num_binned_sets);
        
        % Compute normalized score to rankpoint transform tables
        ns2rp = scoreToRankTransform(ns, ts);
        [ps, stats] = scoreToPercentileTransform(score, dim, minval, maxval, nbins, varargin);
        
        % Convert normalized scores to rankpoints using transform tables
        rp = rankQuery(ns, ns2rp);        
        % score to percentiles 
        [ps, ns] = scoreToPercentile(ns, ns2ps, dim, varargin);
        
        % score to percentiles (size-matched)
        [ps, ns] = scoreToPercentileBySize(ncs, ns2ps_lut, dim, query_size, varargin);
        
        % Aggregate a rank matrix based on a grouping variable
        aggds = aggregateQuery(rp, meta, group, dim,...
                                aggregate_method, aggregate_param);
        % Aggregate a matrix based on grouping set (set membership can overlap)
        agg_ds = aggregateSet(ds, meta, pcl, dim,...
                                match_field, aggregate_method, aggregate_param);
                            
        % Aggregate matrix based on a grouping set split by cell line                            
        agg_ds = aggregateSetByCell(ds, meta, pcl, dim,...
                               match_field, aggregate_method,...
                               aggregate_param);
                           
        % Get paths to touchstone related files                            
        ts_rpt = getTouchStoneFiles(ts_path, pcl_set);
        
        % Get paths files used to compute GUTC background
        ts_rpt = getBackgroundFiles(bkg_path);
        
        % Generate GUTC background lookup files
        genGutcBackground(build_path, introspect_path, out_path, varargin);
        
        % Process raw connectivity scores using unmatched-mode GUTC
        opt = runUnmatchedGutc(varargin);
        saveSingleUnmatchedGutc(res, out_path);
        saveMultiUnmatchedGutc(res, out_path, use_gctx);
                
        
        % Matched mode GUTC
        % current version
        opt = runMatchedGutcV2(varargin);
        % version 1
        opt = runMatchedGutc(varargin);
                
        ds = matchQuery(ds, dim, match_field, id_field);
        saveMultiMatchedGutc(res, out_path, use_gctx);
        
        % Pert Set analysis
        bkg = genPertSetBackground(varargin);
        [ps, agg_ns] = getPertSetPercentile(varargin);
        savePertSetBackground(bkg, outpath);
        
        %ARF
        saveGutcARF(gutc_path, out_path, query_info, make_arf_by_pert, add_query_field);
        
        % digest reports
        makeDigest(gutc_path, out_path, varargin);
        createDigestTables(ds, out_path, args);
        
        % Find closest set size
        nearest_size = getNearestSetSize(ref_size, test_size);
        
        % Cast dataset to wide format
        outds = castDSToWide(ds, varargin);
        
        % Cast dataset to long format
        [outds, row_meta_orig, col_meta_orig] = castDSToLong(ds, row_field, col_field);

        % Compute FDR using the approach in the GSEA paper
        [qval, num, denom] = computeFDRGsea(ncs_all, is_null, ncs_q, apply_null_adjust, apply_smooth);
        % FDR for each column in the dataset
        qval_ds = computeFDRGseaDs(ncs_ds, is_null);
        
    end % Static methods block
       
end
