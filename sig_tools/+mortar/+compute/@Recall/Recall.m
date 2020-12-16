classdef Recall
    
    methods(Static=true)
        
        [pair_recall_rpt, set_recall_rpt, rep_recall_report, rep_stats_rpt, pw_matrices, ds_pairs] = compareReplicates(varargin);
        
        [h, recall_summary] = plotPerPair(pair_recall_rpt, varargin);
        h = plotPerReplicate(recall_rpt, varargin);
        [hf, recall_summary] = plotPerSet(set_recall_rpt, well_field, varargin);
        
        [rep_recall_rpt, rep_stats_rpt] = getReplicateReport(pair_recall_rpt, outlier_alpha);
        stats_rpt = detectOutlierReplicates(measure, replicate_group, varargin);
    end
    
end