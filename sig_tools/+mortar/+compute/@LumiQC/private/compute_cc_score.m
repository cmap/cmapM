% compute sample quality score: rankorder correlation of calib curves
function [ccScore] = compute_cc_score(calibds)

[nCalib,nSample] = size(calibds(1).mat);
ccScore =zeros(nSample,1);
rows = (1:nCalib).';
ccScore(:,1) = corr(rows, rankorder(calibds.mat));
