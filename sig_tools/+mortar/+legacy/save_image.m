
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function save_image (outfile, fmt)


if ~exist('fmt','var')
    fmt ='-dpng';
end

print (gcf, fmt, outfile);
