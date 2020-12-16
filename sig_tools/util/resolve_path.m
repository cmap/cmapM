
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function fp = resolve_path(p, wd)

if length(p) >1
    if (p(1) == '/')
        fp=p;
    else
        np = print_dlm_line(tokenize(p,'../'),1,'/');
        fp = fullfile(wd,p);
    end
else
    fp = wd;
end
