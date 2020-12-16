classdef SigQueryl1k < mortar.base.SigClass
    % SigQueryl1k Compute the geneset enrichment similarity between input genesets (aka queries) and an L1000 dataset
    methods
        function obj = SigQueryl1k(varargin)
            sigName = mfilename('class');
            configFile = mortar.util.File.getArgPath(sigName, '');
            obj@mortar.base.SigClass(sigName, configFile, varargin{:});
        end
    end
    
    methods (Access=protected)
        checkArgs_(obj);
        runAnalysis_(obj, varargin);
        saveResults_(obj, outpath, varargin);
    end % methods block

end