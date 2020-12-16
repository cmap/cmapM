
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function [c1mind,c2mind,prc] = find_markers(sno,snp)

nr=length(sno);

prc = zeros(nr,3);
%compute 5th, 50th and 95th percentiles for each k
for k=1:nr; 
    prc(k,:) = prctile(snp(k,:),[1,50,99]);
end

%markers are those genes with snr score > 95th prtcentile of permuted scores OR
% snr < 5th percentile of permuted scores

%class 1 markers
c1mind = find(sno > prc(:,3));
%class 2 markers
c2mind = find(sno <prc(:,1));
