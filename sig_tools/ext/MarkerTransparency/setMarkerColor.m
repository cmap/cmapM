function [hMarker] = setMarkerColor(handle,color,alpha)
%setMarkerColor Sets face color & transparency of a marker symbol.
%
%   setMarkerColor(handle,color,alpha)
%   Set face color and transparency in marker symbol contained 
%   within a plot handle object.
%
%   INPUTS:
%   handle : handle of plot or marker
%   color  : y-coordinates of markers
%   alpha  : blending of symbol face color (0.0 transparent through 
%            1.0 opaque). (Default : 1.0)
%
%   OUTPUTS:
% 	hMarker : handle of marker
%
%   CAVEAT:
%   Function is fragile with regard to testing for handle type. Desire
%   a better means of testing for the handle property.
%
%   DEPENDENCY:
%   RGBA function that translates a color from multiple formats into a 
%         [R G B alpha] color-transparency
%   RGB  triplet function of Ben Mitch:
%   https://www.mathworks.com/matlabcentral/fileexchange/1805-rgb-m

% Author: Peter A. Rochford
%         Symplectic, LLC
%         www.thesymplectic.com
%         prochford@thesymplectic.com

% Test for handle
if ~ishandle(handle)
    error('Not a handle.')
end

% Get hidden MarkerHandle property (not available in Octave)
drawnow;

% Test for plot handle
test = findobj(handle,'-property','Marker');
if length(test) > 0
    % Plot handle
    hMarker = handle.MarkerHandle;
else
    % Assume marker handle
    hMarker = handle;
end

% Set face color and transparency of marker
hMarker.FaceColorData = uint8(255*rgba(color,alpha));
hMarker.FaceColorType = 'truecoloralpha';

end %function setMarkerColor
