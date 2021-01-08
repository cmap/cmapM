function mkgmt(fname, c, hd, desc)
% MKGMT Create a GMT file
% MKGMT (FNAME, C, HD, DESC)
% MKGMT (FNAME, C) where C is a structure returned by parse_gmt

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
fid=fopen(fname, 'wt');
numrows = length(c);
if isstruct(c)
    % parse_gmt output format
    for ii=1:numrows
        s = print_dlm_line(c(ii).entry);
        fprintf (fid, '%s\t%s\t%s\n', c(ii).head, c(ii).desc, s);
    end
else    
    for ii=1:numrows
        s = print_dlm_line(c{ii});
        fprintf (fid, '%s\t%s\t%s\n', hd{ii}, desc{ii}, s);
    end
end
fclose(fid);
end