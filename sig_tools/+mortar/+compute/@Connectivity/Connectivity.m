classdef Connectivity
% Algorithms to compute connectivity between signatures.

    methods (Static=true)
        
       %== Enrichment based algorithms
       
       %= Core routines
       % Optimized enrichment score computation.
       [esmax, es, rankmax, leadf] = fastESCore(srt_rank, max_rank, isweighted, srt_wt);
       
       %Approximate implementation of contestant WTCS algorithm
       [esmax, es, rankmax, leadf] = fastWTCSCore(srt_rank, max_rank, srt_wt);
       
       % Core implementation of the CMAP score computation.
       [score, leadf] = cmapScoreCore(upind, dnind, ds_rank, ...
                              max_rank, isweighted, ds_score, es_tail);

       % Compute combined score given up and down enrichment scores
       comb_score = getCombinedES(upes, dnes, rescale);
       
       % Validate and filter spurious features
       [up, dn] = checkGenesets(up, dn, rdict, es_tail)

       %= Helper functions   
       % CMap query
       res =  runCmapQuery(varargin);        
       res = computeCmapScore(uptag, dntag,...
                              ds_rank, max_rank, isweighted,...
                              ds_score, es_tail);

       res = computeIntrospect(uptag, dntag,...
                               ds_rank, ds_max_rank,...
                               bkgds_rank, bkgds_max_rank,...
                               es_tail,...
                               isweighted,...
                               ds_score,...
                               bkgds_score);
                           
       % Compare two matrices to each other with wtcs
       sim_mat = compareMatrices(ds1, ds2, varargin);

       % save query results
       saveResult(res, outpath, varargin);
       
       % introspect analysis
       res = runIntrospect(varargin);
       % save introspect results
       saveIntrospect(res, out_path, use_gctx);
       
       % group introspect results
       groupIntrospect(varargin);
       
       % random sampling of connectivity matrix
       [out_ds, out_set] = randSampleSymmetricMatrix(ds, set_size, num_sample, stat_fn);
       
       % Rank-score matrix utilities
       ds_rore = fuseRankScore(ds_score, ds_rank, data_type);
       rore_mat = fuse_rankscore(score_mat, rank_mat, data_type);       
       [ds_score, ds_rank] = defuseRankScore(ds_rore);
       [score_mat, rank_mat] = defuse_rankscore(ds_rore);       
       
       % Recall stats
       rpt = computeRecall(score, col_field, row_field, recall_metric, fix_ties);
       [h, recall_summary] = plotRecall(rpt, varargin);
       [hcell, recall_stats] = plotRecallByGroup(recall_rpt, gp_field, showfig);
       [h, joint_rpt, rpt1_filt, rpt2_filt] = compareRecall(rpt1, rpt2, gp_field);
       
       
       % Xicon
       xicon_sets = getXiconTable(ds_row_meta, xicon_tbl, pcl_set, moa_tbl, match_field);
       xicon_results = getXiconResults(ds, xicon_rpt);
       
       % PosCon Report
       posconReport(zscore, varargin);
       
       % Differential connectivity
       diffconn_rpt = computeDiffConn(varargin);
       
       % mountain plots
       hf = plotEnrichment(ds, gset, varargin);
       hf = plotEnrichmentFast(es_max, es_running, rank_at_max, srt_rank, srt_wt, max_rank, is_weighted);
       
       % generate results structure from querl1k output
       makeResultStruct(res_folder);
       
    end % methods block

end
