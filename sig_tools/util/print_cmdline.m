function o = print_cmdline(cmd, varargin)
% PRINT_CMDLINE Construct commandline call to a sig tool
% PRINT_CMDLINE(CMD, param1, value1, param2, value2,...)
% CMD is a string of the command to call. Returns a quoted string
% that can be evaluated.

p = varargin;
toquote = cellfun(@ischar, p);
p(toquote) = singlequote(p(toquote));
o = sprintf('%s(%s)', cmd, print_dlm_line(p, 'dlm', ', '));
if ~nargout
    fprintf(1, '%s\n', o);
end
    
end