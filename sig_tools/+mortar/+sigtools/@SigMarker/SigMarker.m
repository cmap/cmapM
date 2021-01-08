classdef SigMarker < mortar.base.SigClass
    % Algorithms for marker selection based on two-class comparisons
    methods
        function obj = SigMarker(varargin)
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
