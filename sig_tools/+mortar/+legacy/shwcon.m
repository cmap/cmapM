function labels = shwcon(M,T,sid)
% SHOWCON    Shows the consensus clustering output
%   labels = showcon(M,T,sid) will display the consesnsus
%   clustering matrix as an image and will sort the rows and
%   columns accoring to T, the cluster membership indicator. For
%   each cluster, the sample ids are recorded and outputted in
%   labels. 
%   Inputs: 
%      M - The consensus matrix, n by n.
%      T - A vector which indicates the cluster membership of each
%      sample, 1 by n
%      sid - a cell array which specifies the sample label, 1 by n
%   Outputs: 
%      An image of consesus matrix with rows/columns sorted by
%      cluster membership is outputted. If the sample size is less
%      than 50 then the labels are appended to the
%      image. 
%      labels - a structure where each field is a cell array of
%      sample labels belonging to that particular cluster. 
%
%   See also conclust, conCluster, run_conclust, imagesc
% 
% Author: Brian Geier, Broad 2010 
figure
[~,ix] = sort(T);
imagesc(1-M(ix,ix)), colormap bone
if length(sid) <= 50
  set(gca,'YTick',1:length(sid),'YTickLabel',sid(ix),...
          'XTick',1:length(sid),'XTickLabel',sid(ix));
  rotateticklabel(gca);
end
set(gcf,'Name','ConsensusMatrix')
orient landscape

labels = struct('sid',''); 
idx = unique(T); 
for i = 1 : length(idx)
    labels(i).sid = sid(T==idx(i)); 
end

colorbar
% grid on 