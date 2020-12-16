% Interactive B-spline drawing
% Copyright 2010 Levente Hunyadi
%
% Interactive tool
%   bspline_gui           - Get control points of uniform B-spline interactively.
%
% Examples
%   example_bsplinebasis  - Illustrates B-spline basis functions.
%   example_bsplinedeboor - Illustrates drawing a B-spline.
%   example_bsplinefoot   - Illustrates B-spline foot point calculation.
%   example_bsplineapprox - Illustrates B-spline curve approximation.
%   example_bsplineestim  - Illustrates B-spline curve estimation without knowing parameter values.
%   example_bindevent     - Illustrates how to bind multiple events to a single event hook.
%
% B-spline functions
%   bspline_basis         - B-spline basis function value B(j,n) at x.
%   bspline_basismatrix   - B-spline basis function value matrix B(n) for x.
%   bspline_deboor        - Evaluate explicit B-spline at specified locations.
%   bspline_wdeboor       - Evaluate explicit weighed B-spline at specified locations.
%   bspline_footpoint     - B-spline foot point of a set of points.
%   bspline_approx        - B-spline curve control point approximation with known knot vector.
%   bspline_wapprox       - B-spline curve control point estimation with weight approximation.
%   bspline_estimate      - B-spline curve control point estimation without knowing parameter values.
%
% GUI utility functions
%   gui_bind_event        - Registers a callback on a handle graphics object.
%   gui_dock_vertical     - Automatic layout for controls in a container.
%   guipoints             - Input 2D points from user interactively.
%   uispanedit            - Edit box user control with fixed height but spanning width.
%
% Optimization functions
%   funminbnd             - Single-variable bounded nonlinear function minimization.
