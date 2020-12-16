function lc = linecount(fname)
% LINECOUNT Number of lines in a text file
%   N = LINECOUNT(FNAME) Returns the number of lines in the file FNAME.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

try
    
    [status,result]=system(['wc -l ',fname]);
    
    if isequal(status,0)
        lc=sscanf(result,'%d');
    else
        fid=fopen(fname,'rt');
        lc=0;
        while ~feof(fid)
            tmp = fgetl(fid);
            lc=lc+1;
        end
        
        fclose(fid);
    end
    
catch
    rethrow(lasterror);
end
end
