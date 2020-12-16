function compare_cmdscale(obs,inf,cl,dist_type)
% COMPARE_CMDSCALE Compares the separation of phenotypes in metric space
%   compare_cmdscale(obs,inf,cl,dist_type) will perform classical
%   multidimensional scaling on the datasets obs and inf. Will then draw
%   the output in the context of the known phenotypes, specified in cl. 
%   Inputs: 
%       obs : a p by n matrix
%       inf : a p by n matrix, inferred version of obs
%       cl : a cell array, each element specifies the category of sample i
%       dist_type : the distance matric, input to pdist
%   Outputs: 
%       A few vignettes comparing the two datasets phenotype separation
%       given classical multidimensional scaling. This is a subroutine
%       called by conCluster
%   Note: 
%       the dimensions of obs and inf must be consistent
% 
% see also conCluster, pdist, cmdscale
% 
% Author: Brian Geier, Broad 2010

if nargin == 3
    dist_type = 'euclidean'; 
end
n = size(obs,1); 
obs_dist = pdist(obs,dist_type); 
inf_dist = pdist(inf,dist_type);
y_obs = cmdscale(obs_dist); 
y_inf = cmdscale(inf_dist); 

figure
imagesc([squareform(obs_dist,'tomatrix'),squareform(inf_dist,...
    'tomatrix')])
colormap bluepink
colorbar
h = rectangle('Position',[n,min(ylim),0.5,diff(ylim)]); 
set(h,'FaceColor',[0,0,0]); 
set_marker = [repmat({'Observed'},1,n),repmat({'Inferred'},1,n)]; 
append_sid_cls(set_marker,gcf,'x_axis');
append_sid_cls(cl,gcf,'y_axis'); 
title('Sample Distance Comparison');
set(gcf,'Name',['sample_',dist_type,'_comp']);

figure
imagesc(squareform(obs_dist,'tomatrix')-squareform(inf_dist,...
    'tomatrix'))
title('Sample Distance Change')
append_sid_cls(cl,gcf,'y_axis'); 
append_sid_cls(cl,gcf,'x_axis'); 
colorbar
colormap bluepink
set(gcf,'Name',['sample_',dist_type,'_change']); 

figure
subplot(211) 
gscatter(y_obs(:,1),y_obs(:,2),cl(:)) 
h = legend ; 
set(h,'Location','EastOutside');
title('Observed') 
grid on 
subplot(212)
gscatter(y_inf(:,1),y_inf(:,2),cl(:)) 
h = legend ; 
set(h,'Location','EastOutside');
title('Inferred') 
grid on 

set(gcf,'Name',[dist_type,'_cmd_view']); 