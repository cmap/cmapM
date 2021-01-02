function p = plot(grid,params)
%function p = plot(grid [,params])
% plot function
%
% Parameters:
%   params: object of type plot_params
%
% plot of a rectgrid via plot_polygon_grid
% see help plot_polygon_grid for further information

% Bernard Haasdonk 9.5.2007

if (nargin <2)
  params = [];
end;

% simply forward the call
p = plot_polygon_grid(grid,params);
% TO BE ADJUSTED TO NEW SYNTAX
%| \docupdate 
