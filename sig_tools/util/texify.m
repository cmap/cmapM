%TEXIFY formats special characters for later output
% GDG edit (7/12/06) - Version change

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function out = texify(s)
%deal with $s since we need then for the backslash!
out=regexprep(s,'\$','\$');
%deal with back slashes first

if str2num(matlab_version) > 6.5
    out=regexprep(out,'\\','$\\backslash$');
    %then other special symbols
    out=regexprep(out,'(&|_|{|})','\\$1');
else
    out=regexprep(out,'\\','$\backslash$');
    %then other special symbols
    out=regexprep(out,'(&|_|{|})','\$1','tokenize');
end
