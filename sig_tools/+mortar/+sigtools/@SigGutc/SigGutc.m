classdef SigGutc < mortar.base.SigClass
    % SigGutc Compute percentile connectivity scores to of queries to CMap perturbagens
    methods
        function obj = SigGutc(varargin)
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