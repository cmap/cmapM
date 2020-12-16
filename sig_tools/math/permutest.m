
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function [sno,snp,pl,c1mu,c2mu,ind] = permutest(ge,nl,iter)

[nr,nc] = size(ge);

%compute snr for original data
[sno,c1mu,c2mu] = s2n(ge,nl);

%sort scores and means
[sno,ind]=sort(sno);
c1mu=c1mu(ind);
c2mu=c2mu(ind);

snp = zeros(nr,iter);
pl = zeros(nc,iter);

for ii=1:iter
    pl(:,ii) = nl(randperm(nc));
    sntmp = s2n(ge,pl(:,ii));
    snp(:,ii) = sort(sntmp);    
end
