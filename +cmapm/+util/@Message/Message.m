classdef Message
    % Print messages
    
    methods (Static=true)
        % Print a string if debug flag is set.
        log(fid, s, varargin);
        debug(dbgflag, s, varargin);
        
    end
end