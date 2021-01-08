% FIGUREOFF Create an invisible figure
%   H = FIGUREOFF Create a figure and set its visibility property to off. H
%   is the handle to the figure.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function h = figureoff(varargin)

nin=nargin;
if (nin>0 && all(ishandle(varargin{1})))
    h=figure(varargin{1});
    set(h, 'visible','off');
else
    h=figure('visible','off',varargin{:});
end
