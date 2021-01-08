function append_cluster_membership(T,figure_h,axis_spec) 
% APPEND_CLUSTER_MEMBERSHIP    Append cluster labels to heat map
%   append_cluster_membership(T,figure_h,axis_spec) will append a color box
%   along the y or x axis which indicates cluster membership. That is, if
%   there are three clusters or groupings in T, then there will be three
%   colors with each appearance implying that a particular sample belongs
%   to that cluster. 
%   Inputs: 
%       T : a vector of integers which correspond to groups, common output
%       from Matlab clustering algorithms. 
%       figure_h : The figure handle to manipulate. Default is gcf. 
%       axis_spec : The axis to append the cluster membership coloring.
%       Default is 'y_axis'. Acceptable inputs are 'y_axis' and 'x_axis',
%       which must be strings. 
%   Output: 
%       The axis is manipulated according to the labels specified in T. A
%       different colored rectangle is plotted along the sample axis. 
%       Repeated colors are shown in cases with more than 7 classes. 
% 
% Author: Brian Geier, Broad 2010

if nargin == 1
    figure_h = gcf ; 
    axis_spec = 'y_axis'; 
elseif nargin == 2
    axis_spec = 'y_axis'; 
end

cluster_colors = mkcolorspec(length(unique(T))); 
cl = unique(T); 

switch lower(axis_spec)
    case 'x_axis'

        height = max(0.5,floor(max(ylim)/100)); 
        w = 1; 

        % manipulate plot
        figure(figure_h); 
        y_pt = max(ylim)+0.15;
        current_ylim = ylim; 
        ylim([current_ylim(1),y_pt+height])
        for i = 1 : length(cl)
            x_pt = find(cl(i)==T); 
            for j = 1 : sum(cl(i)==T)
                h = rectangle('Position',[x_pt(j)-.5,y_pt,w,height]); 
                set(h,'FaceColor',cluster_colors{i},'EdgeColor',...
                    cluster_colors{i}); 
            end
        end
        
    case 'y_axis'
        
        height = 1; 
        w = max(0.5,floor(max(xlim)/100)); 

        % manipulate plot
        figure(figure_h); 
        x_pt = min(xlim)-(w+.15);
        current_xlim = xlim; 
        xlim([x_pt,current_xlim(2)])
        for i = 1 : length(cl)
            y_pt = find(cl(i)==T); 
            for j = 1 : sum(cl(i)==T)
                h = rectangle('Position',[x_pt,y_pt(j)-.5,w,height]); 
                set(h,'FaceColor',cluster_colors{i},'EdgeColor',...
                    cluster_colors{i}); 
            end
        end
                
    otherwise
        error('specify either y_axis or x_axis')
        
end