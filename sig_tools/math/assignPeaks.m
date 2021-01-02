function [domPeaks,minPeaks,domProp,minProp] = assignPeaks(peaks,prop)
% see also buildDuo, detect_peaks
[~,ix] = max(prop,[],1); 
ix = squeeze(ix); 
if size(peaks,3) == 1
    ix = ix' ;
end
domPeaks = zeros(size(peaks,2),size(peaks,3)); 
minPeaks = zeros(size(domPeaks)); 
domProp = zeros(size(peaks,2),size(peaks,3)); 
minProp = zeros(size(domProp)); 
for i = 1 : size(peaks,3)
    domPeaks(ix(:,i)==1,i) = peaks(1,ix(:,i)==1,i); 
    domPeaks(ix(:,i)==2,i) = peaks(2,ix(:,i)==2,i); 
    domProp(ix(:,i)==1,i) = prop(1,ix(:,i)==1,i); 
    domProp(ix(:,i)==2,i) = prop(2,ix(:,i)==2,i); 
    minPeaks(ix(:,i)~=1,i) = peaks(1,ix(:,i)~=1,i); 
    minPeaks(ix(:,i)~=2,i) = peaks(2,ix(:,i)~=2,i); 
    minProp(ix(:,i)~=1,i) = prop(1,ix(:,i)~=1,i); 
    minProp(ix(:,i)~=2,i) = prop(2,ix(:,i)~=2,i);
end