function print_args(toolName, fid, s)
% PRINT_ARGS Print parameters.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
if isstruct(s)
    if ischar(fid)
        fid = fopen(fid, 'wt');
        isfile = true;
    else
        isfile = false;
    end
    fprintf (fid, '%s: Parameters\n', toolName);
    pnames = fieldnames(s);
    for ii=1:length(pnames)
        val = stringify(s.(pnames{ii}));
        if iscell(val)
            val = print_dlm_line2(val, 'dlm', ',');
            if length(val)>255
                val=sprintf('%s...',strtrunc(val, 255));
            end
        end
        fprintf (fid, '%s: %s\n',pnames{ii}, val);
    end
    if isfile
        fclose(fid);
    end
end
