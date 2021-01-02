function status = lock(fname)
% LOCK Create a semaphore lockfile.
%   LOCK(FNAME) Creates a lockfile FNAME if it does not exist. Returns 1 on
%   successful creation else returns 0.
%   Note requires lockfile support in the operating system.
%
%   Example
%   if (lock('myfile.lock'))
%       do something
%       unlock('myfile.lock')  
%   end
%   
%   See also UNLOCK

if isdefined('fname') && ischar(fname)
    [exit_code, result] = system(sprintf('lockfile -r0 %s', fname));
    if ~isempty(regexp(result,'Try praying'))        
        if isfileexist(fname)
            exit_code = 1;
        else
            [exit_code, result] = system(sprintf('touch %s', fname));
        end
    end
    status = isequal(exit_code, 0);
else
    error('lock requires a string as input')
end

end