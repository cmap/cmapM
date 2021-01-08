function [cn, nl] = getcls(cl)
% GETCLS Get unique class names
% [CN,NL] = GETCLS(CL) Returns a list of unique class names (CN) from a cell
% array of sample class labels CL. NL is a numeric array of length(CL),where
% 1 = CN{1}, 2=CN{2} etc.
% See Also: MKCLS

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT


[nl, cn, gl] =  grp2idx(cl);
if isnumeric(cl)
    cn = gl;
end
end
