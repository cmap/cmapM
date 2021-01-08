function mk = getmk(M,T)
% subroutine called by conclust
% see also conclust, conCluster
% Estimates the mk parameter from Monti, et al, Consensus Cluster - Machine
% Learning paper

num_clusters = length(unique(T)); 
mk = zeros(1,num_clusters); 
    
for i = 1 : num_clusters
    nk = sum(T==i); 
    step = triu(M(T==i,T==i)); 
    mk(i) = (1/(nk*(nk-1)/2))*(sum(step(:)) - nk); 
end