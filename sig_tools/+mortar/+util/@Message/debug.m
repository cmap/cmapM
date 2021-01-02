function debug(dbgflag, s, varargin)
% DEBUG Print a string if debug flag is set.
% DEBUG(DBGFLAG, S, arg1, arg2) prints S to the console. Evaluates S with
% arguments if provided
%   Example::
%   debug(1, 'file loaded: %s', 'foo.txt')

if dbgflag
    str = feval(@sprintf, s, varargin{:});
    fprintf ('%s\n', str)
end
end