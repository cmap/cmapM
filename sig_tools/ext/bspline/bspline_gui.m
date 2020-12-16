function P = bspline_gui(n)
% Get control points of uniform B-spline interactively.
% The user is shown a figure window in which to choose B-spline control
% points. As points are placed in the axes, the B-spline of specified order
% is drawn progressively. The user may terminate adding control points by
% pressing ENTER or ESC, or may place the last control point with a right
% mouse button click. Once done, control points may be adjusted with
% drag-and-drop. Control point adjustment can work in 3D; use the rotation
% tool to set a different camera position.
%
% Input arguments:
% n (optional):
%    B-spline order (defaults to cubic spline, n = 4)

% Copyright 2010 Levente Hunyadi

    if nargin < 1
        n = 4;  % use cubic splines by default
    else
        validateattributes(n, {'numeric'}, {'positive','integer','scalar'});
    end

    fig = figure( ...
        'Name', 'Interactive uniform B-spline', ...
        'NumberTitle', 'off');

    % axes for drawing
    ax = axes('Parent', fig, ...
        'Units', 'normalized', ...
        'OuterPosition', [0.2 0 0.8 1], ...
        'DrawMode','fast', ...
        'XLimMode', 'manual', ...
        'YLimMode', 'manual', ...
        'ZLimMode', 'manual');

    % dock panel
    panel = uipanel(fig, ...
        'Units', 'normalized', ...
        'Position', [0 0 0.15 1], ...
        'BackgroundColor', get(fig, 'Color'), ...
        'ForegroundColor', get(fig, 'Color'), ...
        'HighlightColor', get(fig, 'Color'), ...
        'BorderType', 'line', ...
        'BorderWidth', 5);
    editx = uispanedit(panel, ...
        'Height', 25, ...
        'HorizontalAlignment', 'left', ...
        'TooltipString', 'x coordinate', ...
        'Callback', @bspline_gui_setpoint);
    edity = uispanedit(panel, ...
        'Height', 25, ...
        'HorizontalAlignment', 'left', ...
        'TooltipString', 'y coordinate', ...
        'Callback', @bspline_gui_setpoint);
    editz = uispanedit(panel, ...
        'Height', 25, ...
        'HorizontalAlignment', 'left', ...
        'TooltipString', 'z coordinate', ...
        'Callback', @bspline_gui_setpoint);
    editw = uispanedit(panel, ...
        'Height', 25, ...
        'HorizontalAlignment', 'left', ...
        'TooltipString', 'weight', ...
        'Callback', @bspline_gui_setpoint);
    gui_dock_vertical(panel);

    x = [];       % x-coordinate of control points
    y = [];       % y-coordinate of control points
    z = [];       % z-coordinate of control points
    w = [];       % weights of control points
    ix = [];      % index of currently selected point
    dragix = [];  % index of currently selected point for dragging

    ctrl = line(-1, -1, ...
        'Parent', ax, ...
        'Color', 'b', ...
        'Marker', 'x');
    spline = line(0, 0, ...
        'Parent', ax, ...
        'Color', 'r');
    selection = line(-1, -1, ...
        'Parent', ax, ...
        'Color', 'b', ...
        'Marker', 'o');

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

                case 3   % right mouse button
                    cancel = true;
                case 27  % ESC key
                    cancel = true;
                    continue;  % quit from loop without adding point
            end
            x = [x,x1]; %#ok<AGROW>
            y = [y,y1]; %#ok<AGROW>
            z = [z,0];  %#ok<AGROW>
            w = [w,1];  %#ok<AGROW>

            set(ctrl, 'XData', x, 'YData', y);
            bspline_gui_drawspline();
        end
        set(fig, 'WindowButtonDownFcn', @bspline_gui_onmousedown);
        set(fig, 'WindowButtonUpFcn', @bspline_gui_onmouseup);
        set(fig, 'WindowButtonMotionFcn', @bspline_gui_onmousemove);
        uiwait(fig);
    catch ex
        switch ex.identifier
            case 'MATLAB:ginput:FigureDeletionPause'
                % preserve values for x and y
            otherwise
                rethrow(ex);
        end
    end
    if nnz(z) > 0  % 3D
        P = [x;y;z];
    else  % 2D
        P = [x;y];
    end
    if nargout < 1
        disp(mat2str(P,4));
    end

    function bspline_gui_drawspline()
    % Draws a uniform B-spline.
        if n <= 2 || numel(x) < n  % not meaningful to draw constant or linear spline, or insufficient control points to draw higher-order spline
            return;
        end
        t = [ zeros(1, n-1) linspace(0,1,numel(x)-n+2) ones(1, n-1) ];  % knot vector
        X = bspline_wdeboor(n,t,[x;y;z],w);
        set(spline, 'XData', X(1,:), 'YData', X(2,:), 'ZData', X(3,:));
    end

    function bspline_gui_onmousedown(fig, event) %#ok<INUSD>
    % Fired when the user presses the mouse button.
        cp = get(ax, 'CurrentPoint');
        [q,dist] = project_points_line([x;y;z], transpose(cp(1,:)), transpose(cp(2,:))); %#ok<ASGLU>
        [mindist,minix] = min(dist);  % closest point
        if mindist < 0.05
            dragix = minix;  % grab point
            ix = dragix;
            bspline_gui_select();
        end
    end

    function bspline_gui_onmouseup(fig, event) %#ok<INUSD>
    % Fired when the user releases the mouse button.
        dragix = [];  % no currently selected point
    end

    function bspline_gui_onmousemove(fig, event) %#ok<INUSD>
    % Fired when the user moves the mouse.
        if isempty(dragix)  % no point selected (not in drag mode)
            return;
        end
        cp = get(ax, 'CurrentPoint');
        q = project_points_line([x(dragix);y(dragix);z(dragix)], transpose(cp(1,:)), transpose(cp(2,:)));  % project current point to line of selection
        q = coerce_range(q, 0, 1);  % force position into unit range
        x(dragix) = q(1);
        y(dragix) = q(2);
        z(dragix) = q(3);
        bspline_gui_redraw();
    end

    function bspline_gui_select()
    % Update current selection.
        if ~isempty(ix)
            set(selection, 'XData', x(ix), 'YData', y(ix), 'ZData', z(ix), 'Visible', 'on');
        else
            set(selection, 'XData', x(ix), 'YData', y(ix), 'ZData', z(ix), 'Visible', 'off');
        end
        bspline_gui_getpoint();
        drawnow;
    end

    function bspline_gui_redraw()
    % Redraw control polygon and current selection.
        set(ctrl, 'XData', x, 'YData', y, 'ZData', z);
        bspline_gui_drawspline();
        bspline_gui_select();
    end

    function bspline_gui_getpoint()
    % Update point data displayed in docked panel.
        if isempty(ix)
            return;
        end
        set(editx, 'String', num2str(x(ix), 3));
        set(edity, 'String', num2str(y(ix), 3));
        set(editz, 'String', num2str(z(ix), 3));
        set(editw, 'String', num2str(w(ix), 3));
    end

    function bspline_gui_setpoint(editctrl, event) %#ok<INUSD>
    % Update point coordinates based on values in docked panel.
        if isempty(ix)
            return;
        end
        xd = str2double(get(editx, 'String'));
        yd = str2double(get(edity, 'String'));
        zd = str2double(get(editz, 'String'));
        wd = str2double(get(editw, 'String'));
        if isnan(xd) || isnan(yd) || isnan(zd) || isnan(wd)
            return;
        end
        x(ix) = xd; y(ix) = yd; z(ix) = zd; w(ix) = wd;
        bspline_gui_redraw();
    end
end

function [Q,dist] = project_points_line(P, p1, p2)
% Project points P to a line given by two points p1 and p2.
%
% Input arguments:
% P:
%    an n-by-M matrix of M points to project
% p1, p2:
%    an n-by-1 column vectors that define the line
%
% Output arguments:
% Q:
%    an n-by-M matrix of M projected points
% dist:
%    a vector of distances between original and projected points

    validateattributes(P, {'numeric'}, {'real','2d'});
    validateattributes(p1, {'numeric'}, {'real','column'});
    validateattributes(p2, {'numeric'}, {'real','column'});

    p1 = p1(:);
    p2 = p2(:);
    d = (p1-p2) / norm(p1-p2);  % unit direction vector of line
    Q = bsxfun(@plus, p1, bsxfun(@times, (d' * bsxfun(@minus, P, p1)), d));  % projection of points on line
    if nargout > 1
        dist = sqrt(sum((P-Q).^2, 1));  % distance of original points and projections
    end
end

function M = coerce_range(M, lower, upper)
% Coerce entries of an array into the specified range.

    M(M < lower) = lower;
    M(M > upper) = upper;
end