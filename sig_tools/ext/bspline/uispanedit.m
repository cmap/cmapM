function editbox = uispanedit(varargin)
% Edit box user control with fixed height but spanning width.
%
% This user control automatically takes all available space for width but
% maintains a fixed height when resizing.

% Copyright 2010 Levente Hunyadi

ix = 1;
if nargin >= ix && ishandle(varargin{ix})
    parent = varargin{ix};
    ix = ix + 1;
end

ixheight = 2*strmatch('Height', varargin(ix:2:end))-1;  % offset of parameter 'Height'
if ~isempty(ixheight)
    height = varargin{ix + ixheight};
    varargin(ix + ixheight - 1 : ix + ixheight) = [];  % remove parameter 'Height'
else
    height = 25;
end

editbox = uicontrol(parent, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'Position', [0,0,1,1], ...
    varargin{ix:end});
fig = ancestor(parent, 'figure');
uispanedit_resize(fig, [], editbox, height);
gui_bind_event(fig, 'ResizeFcn', {@uispanedit_resize, editbox, height});

function uispanedit_resize(fig, event, editbox, height)

pos = getpixelposition(editbox);
left = pos(1); bottom = pos(2); width = pos(3);
setpixelposition(editbox, [left, bottom, width, height]);