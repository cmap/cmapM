classdef SigGseaPreranked < mortar.base.SigClass
    % SigGseaPreranked Run GSEA on rank-ordered lists
    methods
        function obj = SigGseaPreranked(varargin)
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