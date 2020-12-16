function dbg(varargin)
% DBG Print a string if debug flag is set.
% DBG(DBGFLAG, S, arg1, arg2) prints S to the console. Evaluates S with
% arguments if provided
%   Example::
%   dbg(1, 'file loaded: %s', 'foo.txt')

% if dbgflag
%     str = feval(@sprintf, s, varargin{:});
%     fprintf ('%s\n', str)
% end

mortar.util.Message.debug(varargin{:});

end