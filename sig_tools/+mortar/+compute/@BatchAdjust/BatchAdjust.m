classdef BatchAdjust
    % Batch Adjustment algorithms
    methods(Static=true)
        % Mean-variance standardization
        y = adjustMeanVariance(x, b, method);
        
        % Apply Mean-variance standardization to PRISM data
        adj_ds = adjustMeanVariancePrism(ds, col_group, row_group,...
                                         col_gp_as_batch, method);
        % Batch statistics
        batch_stats = getBatchStats(ds, dim, batch);
        
        % Batch enrichment
        batch_res = getBatchEnrichment(ds, dim, batch);
        
        %guidedPCA;
        
    end
end