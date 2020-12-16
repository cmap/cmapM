function h = viewperf(cm,mcr,tpr,groups,method)
% VIEWPERF  Routine for displaying confusion matrix 
%   h = viewperf(cm,mcr,tpr,groups,method) displays the confusion
%   matrix as an image. The counts for each hypothesis are
%   overlayed on an image of percentage assigned per class. 
%   Inputs:  
%      cm - a confusion matrix, num_classes by num_classes
%      mcr - the miss-classification rate
%      tpr - the true positive classification rate
%      groups - a cell array specifiying the class names, order
%      consistent with the rows/cols of cm
%      method - a string which specifies the classification algorithm
%   Outputs: 
%      h - the figure handle
%
%   Note: This is a subroutine called by compareClassification
%   See also compareClassification
% 
% Author: Brian Geier, Broad 2010   

figure
num_groups = length(groups); 
pct = zeros(size(cm)); 
for i = 1 : size(cm,1)
    pct(i,:) = cm(i,:)./sum(cm(i,:)); 
end
font_size = 15; 
% drop_sig = -1; % round to 1 significant digits
imagesc(pct), colorbar
set(gca,'YTick',1:num_groups,'XTick',1:num_groups,'YTickLabel',groups,...
    'XTickLabel',groups,'FontSize',font_size); 

for i = 1 : num_groups 
    for j = 1 : num_groups
        text(i-.25,j,num2str(cm(j,i)),...
            'FontSize',font_size); 
%         text(i-.25,j,horzcat(num2str(roundn(100*pct(j,i),drop_sig)),'% ',...
%             groups{j}, ' allocated'),...
%             'FontSize',font_size); 
    end
end
h = xlabel('Assigned Labels','FontSize',font_size); 
set(h,'Position',[num_groups/2,num_groups+1,num_groups/2]); 
ylabel('True Labels','FontSize',font_size); 
title(horzcat('Overall: tpr = ',num2str(tpr),' mcr = ',...
    num2str(mcr),' - ',method)); 
rotateticklabel(gca); 
orient landscape
h = gcf  ; 

set(gcf,'Name',horzcat('ConfusionMat_',method)) ;