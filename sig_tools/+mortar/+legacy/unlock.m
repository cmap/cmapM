function status = unlock(fname)
% UNLOCK Remove a semaphore lockfile.
%   UNLOCK(FNAME) Removes the lockfile FNAME. Returns 1 on successful
%   deletion or 0 otherwise.
%
% See also LOCK

if isdefined('fname') && ischar(fname)
    if isfileexist(fname)
        [exit_code, result] = system(sprintf('rm -f ''%s''', fname));
        status = isequal(exit_code, 0);
    else
        status = 0;
    end
else
    error('unlock requires an existing filename as input')
end

end