classdef SigSlice < mortar.base.SigClass
    % SigSlice Extract a subset from a larger dataset       
    methods
        function obj = SigSlice(varargin)
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