function [cn, nl] = getcls(cl)

% GETCLS Get unique class names
% [CN,NL] = GETCLS(CL) Returns a list of unique class names (CN) from a cell 
% array of sample class labels CL. NL is a numeric array of length(CL),where 
% 1 = CN{1}, 2=CN{2} etc.
% See Also: MKCLS

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

%function [cn,nl,clidx] = getcls(cl, reorder)

[nl, cn] =  grp2idx(cl);

% if (exist('reorder','var'))
%     isreorder=reorder;
% else
%     isreorder=true;
% end


% % number of samples
% nsamp = length(cl);
% 
% [ucl,i]=unique(cl);
% 
% % number of classes
% nclass =  length(ucl);
% 
% if isreorder
%     % reorder according to input
%     cn=cl(sort(i));
% else
%     % dont reorder
%     cn=ucl;
% end
% %numeric labels for each class
% nl=zeros(nsamp,1);
% % first index into cl for each class
% clidx=zeros(nclass,1);
% 
% for ii=1:nclass; 
%     ind=strmatch(cn{ii},cl,'exact');    
%     nl(ind) = ii;    
%     clidx(ii) = ind(1);
% end
