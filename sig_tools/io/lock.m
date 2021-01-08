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

% use system lockfile if it exists
[exit_code, lockfile_bin] = system('which lockfile');
lockfile_bin = str_deblank(lockfile_bin, 'both');

if exit_code>0
    % fallback to user binary (on CMap servers)
    dbg(1, 'Using lockfile fallback');
    lockfile_bin='/cmap/bin/lockfile';
end

assert(mortar.util.File.isfile(lockfile_bin, 'file'), '%s not found', lockfile_bin);
[exit_code, result] = system(sprintf('%s -v', lockfile_bin));
if ~isequal(exit_code, 64)
    error('Error executing lock (%s) : %s ', lockfile_bin, deblank(result));
end

if isdefined('fname') && ischar(fname)
    [exit_code, result] = system(sprintf('%s -r0 %s', lockfile_bin, fname));
    if ~isempty(regexp(result,'giving up on', 'once'))        
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
