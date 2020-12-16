function [edg,clen] = class_edg(nl)
% CLASS_EDG
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

nsample = length(nl);
% nclass = length(cn);
% nbars = size(nl,2);

%end idx for each class
edg = [mod(find(diff(nl))-1,nsample)+1; nsample];

%length of each class
clen = diff([0;edg]);
