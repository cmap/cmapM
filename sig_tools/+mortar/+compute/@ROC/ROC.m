classdef ROC
    % Methods for ROC analysis
    methods(Static=true)
        [perf_rpt, perf_summary] = computeROC(varargin);
        hf_perf = plotPerfThreshold(roc_rpt, roc_summary);
        hf_roc = plotROC(roc_rpt, roc_summary);
        f = fscore(tpr, ppv, beta);
    end
end