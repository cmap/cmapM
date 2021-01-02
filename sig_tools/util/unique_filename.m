%UNIQUE_FILENAME Ensure that a filename is unique.
%   UFN = UNIQUE_FILENAME(FN) Checks if FN exists. If it does, appends a
%   number suffix after the filename to make the filename unique.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function ufn = unique_filename(fn, varargin)

nin = nargin;
if nin >= 1

    param_defaults = {
        'format', 'numeric', ... % numeric, timestamp
        };

    [eid, emsg, fmt] = ...
        getargs(param_defaults(1:2:end), param_defaults(2:2:end), varargin{:});

    [p,f,e] = fileparts(fn);

    ufn = fn;
    ctr=1;
    while exist(ufn,'file')
        
        switch (fmt)
            case 'numeric'
                ufn = fullfile(p,sprintf('%s_%d%s',f,ctr,e));
                ctr=ctr+1;
            case 'timestamp'
                timestr = lower(datestr(now, 'mmmdd_HHMMSS'));
                ufn = fullfile(p,sprintf('%s_%s%s',f,timestr,e));
            otherwise
                error('Unknown format: %s', fmt);
        end
    end
else
    
    help (mfilename)

end
