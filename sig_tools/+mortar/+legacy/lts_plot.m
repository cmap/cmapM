function lts_plot(vals,g,type)
% LTS_PLOT Ligand/Target Saliency plot for SMM
%   LTS_PLOT(vals,g,type) will make a ligand-target saliency plot. The plot
%   type is either boxplot or single points arrayed by category. 
%   
%   Inputs:
%       vals: an n-by-1 vector
%       g: a cell array where each element indicates the class of the
%       corresponding index in vals
%       type: the type of plot, either 'box' (boxplot) or 'points'
% 
%   Notes: figure is drawn into available window, and group labels are
%   appended given values in g
% 
% Author: Brian Geier, Broad 2010

if nargin ==2
    type ='box'; 
end
switch type
    case 'box'
        boxplot(vals,g,'plotstyle','compact','orientation','horizontal'); 
        
    case 'points'
        cl = unique_ord(g);
        num_cl = length(cl); 
        levels = zeros(size(g)); 
        for i = 1 : num_cl
            levels(strcmp(cl{i},g)) = i; 
        end
        plot(vals,levels,'o')
        set(gca,'YTick',1:length(cl),'YTickLabel',cl); 
        ylim([1,length(cl)])
    otherwise 
        error('check type input')
end

xlim([0,max(vals(:))+1])

orient tall ; 