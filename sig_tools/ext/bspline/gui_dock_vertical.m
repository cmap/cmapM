function gui_dock_vertical(container, varargin)
% Automatic layout for controls in a container.
%
% Input arguments:
% container:
%    container whose controls to lay out
% width:
%    width in pixels for the container to dock

% Copyright 2010 Levente Hunyadi

fig = ancestor(container, 'figure');

padding = 3;
width = [];
for k = 1 : 2 : numel(varargin)
    value = varargin{k+1};
    switch varargin{k}
        case 'Padding'
            padding = value;
        case 'Width'
            width = value;
    end
end

validateattributes(padding, {'numeric'}, {'positive','integer','scalar'});
if ~isempty(width)
    validateattributes(width, {'numeric'}, {'positive','integer','scalar'});
end

gui_bind_event(fig, 'ResizeFcn', {@gui_dock_vertical_layout, container, padding});
if ~isempty(width)
    gui_bind_event(fig, 'ResizeFcn', {@gui_dock_vertical_resize, container, width});
end

function gui_dock_vertical_layout(fig, event, container, padding) %#ok<INUSL>
% Callback for the resize event of figure to dock controls of container.
%
% Input arguments:
% fig:
%    a figure handle
% event:
%    an event structure
% container:
%    container whose controls to lay out

bottom = padding;
children = get(container, 'Children');
for k = 1 : numel(children)
    child = children(k);
    pos = getpixelposition(child);
    width = pos(3); height = pos(4);
    setpixelposition(child, [0, bottom, width, height]);
    bottom = bottom + height + padding;
end

function gui_dock_vertical_resize(fig, event, container, width) %#ok<INUSL>
% Callback for the resize event of figure to maintain dock container size.
%
% Input arguments:
% fig:
%    a figure handle
% event:
%    an event structure
% container:
%    container to dock

pos = getpixelposition(container);
height = pos(4);
setpixelposition(container, [0, 0, width, height]);
