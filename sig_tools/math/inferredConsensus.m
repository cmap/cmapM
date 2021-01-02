function [M,T,Z,mk] = inferredConsensus(obs,inf,num_clusters,cls)
% INFERREDCONSENSUS     Performs Comparative Conensus between two datasets
%   [M,T,Z] = inferredConsensus(obs,inf,sid,varargin) will perform
%   consensus clustering on the datsets obs and inf. These datasets are
%   taken to be the observed and inferred sets of a given collection. A few
%   plots comparing the conensus clustering are produced. The output from
%   conclust is outputted for both datasets. 
%   Inputs: 
%       obs : an n by p matrix of data
%       inf : an n by p matrix of data
%       sid : a cell array specifying the sample labels
%       num_clusters : a scalar specifying the number of clusters. If
%       num_clusters = 0, then an automatic search is initiated over 2
%       to 15 in the 'obs' data space. 
%   Outputs: 
%       The objects M,T, and Z are structures with the fieldnames 'obs' and
%       'inf. 
%       M : The consensus matrix
%       T : The cluster assignment given 1-M
%       Z : The linkage output given 1-M dissimilarity matrix
% 
%   See also conclust, conCluster
% 
% Author: Brian Geier, Broad 2010

if num_clusters ~= 0
    [M.obs,T.obs,Z.obs,mk.obs] = conclust(obs,num_clusters); 
    [M.inf,T.inf,Z.inf,mk.inf] = conclust(inf,num_clusters); 
else
    [M.obs,T.obs,Z.obs,mk.obs,num_clusters] = conclust(obs,2:15); 
    [M.inf,T.inf,Z.inf,mk.inf] = conclust(inf,num_clusters); 
end

figure
if length(unique(cls.labels)) ~= length(cls.labels)
    imagesc(1-M.obs)
    append_cluster_membership(T.obs,gcf,'x_axis'); 
    append_cluster_membership(T.obs,gcf,'y_axis'); 
    append_sid_cls(cls.labels,gcf,'y_axis'); 
    append_sid_cls(cls.labels,gcf,'x_axis'); 
else
    [sortedT,ix] = sort(T.obs);
    imagesc(1-M.obs(ix,ix))
    append_cluster_membership(sortedT,gcf,'x_axis'); 
    append_cluster_membership(sortedT,gcf,'y_axis'); 
end
title('Observed Consensus')
colormap bone
colorbar
set(gcf,'Name','obs_consensus'); 

figure

if length(unique(cls.labels)) ~= length(cls.labels)
    imagesc(1-M.inf)
    append_cluster_membership(T.inf,gcf,'x_axis'); 
    append_cluster_membership(T.inf,gcf,'y_axis'); 
    append_sid_cls(cls.labels,gcf,'y_axis'); 
    append_sid_cls(cls.labels,gcf,'x_axis'); 
else
    [sortedT,ix] = sort(T.inf);
    imagesc(1-M.inf(ix,ix))
    append_cluster_membership(sortedT,gcf,'x_axis'); 
    append_cluster_membership(sortedT,gcf,'y_axis'); 
end
title('Inferred Consensus')
set(gcf,'Name','inf_consensus'); 
colormap bone
colorbar

figure
ecdf(M.obs(:))
hold on ; grid on ; 
[f,x] = ecdf(M.inf(:)); 
stairs(x,f,'r')
xlim([0.1 0.9])
legend('Observed','Inferred','Location','NorthWest')
title('Comparison of Consensus Distributions')
set(gcf,'Name','consensusdist'); 

%% Individual cluster consensus metrics

% figure
% ecdf(mk.obs)
% hold on ; grid on ; [f,x] = ecdf(mk.inf); 
% stairs(x,f,'r')
% legend('Observed','Inferred','Location','NorthWest')
% title('Comparison of Individual Consensus Cluster')
% 
% figure
% imagesc([mk.obs' mk.inf'])
% set(gca,'XTick',[1 2],'XTickLabel',{'Observed','Inferred'},'YTick',[])
% colormap winter
% colorbar
% title('Individual Cluster Consensus')
% ylabel('Clusters')