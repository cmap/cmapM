function [status, result] = chmod(filename, mode)
try
    
    [status, result]=system(sprintf('chmod %s %s', mode, filename));    
    
catch me
    error('%s, %s: %s', filename, me.identifier, me.message);
end
end