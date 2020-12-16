classdef SigTestMLR < mortar.base.SigClass
    % SigTestMLR "Apply given model to predict genes using multiple linear regression."
    methods
        function obj = SigTestMLR(varargin)
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