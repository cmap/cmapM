function P = guipoints
% Input 2D points from user interactively.

% Copyright 2010 Levente Hunyadi

fig = figure;
ax = axes( ...
    'Parent', fig, ...
    'XLimMode', 'manual', ...
    'YLimMode', 'manual');
x = [];
y = [];
ctrl = line(-1, -1, ...
    'Parent', ax, ...
    'LineStyle', 'none', ...
    'Marker', 'x');
try
    cancel = false;
    while ~cancel
        [x1,y1,button] = ginput(1);
        if isempty(x1) || isempty(y1)  % ENTER key
            break;
        elseif x1 < 0 || x1 > 1 || y1 < 0 || y1 > 1  % point outside domain
            continue;
        end
        switch button
            case 1   % left mouse button
                % record data
            case 3   % right mouse button
                cancel = true;  % cancel with adding point
            case 27  % ESC key
                cancel = true;  % cancel without adding point
                continue;
        end
        x = [x,x1]; %#ok<AGROW>
        y = [y,y1]; %#ok<AGROW>

        set(ctrl, 'XData', x, 'YData', y);
    end
catch ex
    switch ex.identifier
        case 'MATLAB:ginput:FigureDeletionPause'
            % preserve values for x and y
        otherwise
            rethrow(ex);
    end
end
P = [x;y];
if nargout < 1
    disp(mat2str(P,4));
end