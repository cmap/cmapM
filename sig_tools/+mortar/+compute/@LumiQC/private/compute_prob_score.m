function [pMat,pScore] = compute_prob_score(calibds)

[nCalib,nSample] = size(calibds.mat);
pMat = zeros(nCalib,nCalib);
pScore = zeros(nSample,1);

rows = (1:nCalib).';

[sc, sci] = sort(calibds.mat);
for ii=1:nCalib;
    pMat(ii,:)=hist(sci(ii,:),(0.5:nCalib-0.5))/nSample;
end

thisPMat = pMat(:,:);

for ii=1:nSample
    pScore (ii) = mean(thisPMat(rows + (sci(:,ii)-1)*nCalib));
end
