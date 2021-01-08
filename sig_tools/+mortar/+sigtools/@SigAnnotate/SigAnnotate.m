classdef SigAnnotate < mortar.base.SigClass
    % SigAnnotate Read and Modify metadata for a dataset
    methods
        function obj = SigAnnotate(varargin)
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