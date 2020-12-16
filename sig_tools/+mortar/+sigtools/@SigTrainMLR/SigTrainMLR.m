classdef SigTrainMLR < mortar.base.SigClass
    % SigTrainMLR "Create a model given a dataset using multilinear regression."
    methods
        function obj = SigTrainMLR(varargin)
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