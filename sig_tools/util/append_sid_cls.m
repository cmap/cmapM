function append_sid_cls(cl,figure_h,axis_spec)
% APPEND_SID_CLS    Append class labels to heat map
%   append_sid_cls(cl,figure_h) will append individual class labels to the
%   midpoint of the observed class indices. The samples should be grouped
%   via class prior to function call. 
%   Inputs: 
%       cl : a cell array where the ith element specifies the ith samples
%       class membership. 
%       figure_h : an integer specifying the graphics object to manipulate
%       gcf is the default .
%   Output: 
%       The axis is manipulated according to the labels specified in cl. A
%       different colored rectangle is plotted along the sample axis with
%       the class label at its midpoint. Repeated colors are shown in cases
%       with more than 7 classes. 
% 
% Author: Brian Geier, Broad 2010

if nargin == 1
    figure_h = gcf ; 
    axis_spec = 'x_axis'; 
elseif nargin == 2
    axis_spec = 'x_axis'; 
end


% define variables, and pre-allocate arrays
labels = unique_ord(cl) ; 

switch lower(axis_spec)
    case 'x_axis'

        height = max(0.5,floor(max(ylim)/100)); 
%         w = 1; 
        w = zeros(1,length(labels)); 
        pts = zeros(1,length(labels)); 
        x_pt = zeros(1,length(labels)); 

        % Build rectangle() call parameters given 'cl' input
        for i = 1 : length(labels)
            ix = find(strcmp(labels{i},cl)); 
            pts(i) = floor(median(ix)); 
            w(i) = length(ix); 
            x_pt(i) = min(ix); 
        end

        % manipulate plot
        figure(figure_h); 
        set(gca,'XTick',pts,'XTickLabel',labels); 
        y_pt = max(ylim)+0.15; 
        current_ylim = ylim; 
        ylim([current_ylim(1),y_pt+height])
        colors = mkcolorspec(length(labels)); 
        for i = 1 : length(labels)
            h = rectangle('Position',[x_pt(i)-.5,y_pt,w(i),height]); 
            set(h,'FaceColor',colors{i}); 
        end
        if length(labels) > 2
            rotateticklabel(gca);
        end
        
    case 'y_axis'


%         height = 1; 
        w = max(0.5,floor(max(xlim)/100));
        height = zeros(1,length(labels)); 
        pts = zeros(1,length(labels)); 
        y_pt = zeros(1,length(labels)); 

        % Build rectangle() call parameters given 'cl' input
        for i = 1 : length(labels)
            ix = find(strcmp(labels{i},cl)); 
            pts(i) = floor(median(ix)); 
            height(i) = length(ix); 
            y_pt(i) = min(ix); 
        end

        % manipulate plot handle
        figure(figure_h); 
        set(gca,'YTick',pts,'YTickLabel',labels); 
        x_pt = min(xlim)-0.15; 
        current_xlim = xlim; 
        xlim([x_pt-w,current_xlim(2)])
        colors = mkcolorspec(length(labels)); 
        for i = 1 : length(labels)
            h = rectangle('Position',[x_pt-w,y_pt(i)-.5,w,height(i)]); 
            set(h,'FaceColor',colors{i}); 
        end
        
    otherwise
        error('specify either y_axis or x_axis')
        
end