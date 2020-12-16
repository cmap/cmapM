function [h_right, h_left] = ylabelrt(s, varargin)
isvisible = isequal(get(gcf,'visible'),'on');
h_left = gca;
h_right = axes;
set(h_right, 'yaxislocation', 'right', 'ytick', [], 'xtick', [])
ylabel(s, varargin{:})
if isvisible
    axes(h_left);
else
    axesoff(h_left);
end
% set(gcf,'visible', isvisible);
end