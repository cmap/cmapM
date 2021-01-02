function ncs = cs2normcs(cs)
% CS2NORMCS Compute normalized connectivity scores. 
% NCS = CS2NORMCS(CS) The scores are scaled by the signed mean of the
% provided scores.

pos_cs = cs>0;
neg_cs = cs<0;
pos_mu = clip(mean(cs(pos_cs)), 0.01, inf);
neg_mu = clip(abs(mean(cs(neg_cs))), 0.01, inf);
ncs = cs;
ncs(pos_cs) = ncs(pos_cs)/pos_mu;
ncs(neg_cs) = ncs(neg_cs)/neg_mu;

end