classdef SetEnrichment
    % Set enrichment analysis
    methods (Static = true)
        res = runAnalysis(varargin);
        saveResult(res, outpath);
    end
end