classdef SigScore2Rank < mortar.base.SigClass
    % SigScore2Rank Generate rank matrix from score matrix
    methods
        function obj = SigScore2Rank(varargin)
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