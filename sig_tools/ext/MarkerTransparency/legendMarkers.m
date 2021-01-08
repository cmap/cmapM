function legendMarkers(handle,hLegend,lMarker,alpha)
%legendMarkers Apply color & transparency to legend markers
%
%   The legend function clears marker customizations such as
%   transparency, so restore transparency by re-updating the
%   markers. Also apply transparency to the symbols appearing
%   in the legend.
%
%   LEGENDMARKERS(HANDLE,HLEGEND,LMARKER,ALPHA)
%
%   INPUTS:
%   handle  : handle of plot
%   hLegend : handle of legend
%   lMarker : list of marker symbols
%   alpha   : blending of symbol face color (0.0 transparent through 
%             1.0 opaque). (Default : 1.0)
%
%   OUTPUTS:
% 	None

% Test for empty arrays
if length(handle) == 0 || length(hLegend) == 0 || length(lMarker) == 0
    error('handle is empty array');
elseif length(hLegend) == 0
    error('hLegend is empty array');
elseif length(lMarker) == 0
    error('lMarker is empty array');
elseif length(handle) ~= length(lMarker)
    error('handle and lMarker arrays must be same size');
end

% Necessary to do a drawnow before operating on the legend structure
drawnow;

% Process for all markers
for i=1:length(lMarker)
    % Restore marker transparency
    setMarkerColor(handle(i),lMarker(i),alpha);
end

% Get legend components
% hLegendComponents has 2 children: child 1 = LegendIcon, child 2 = Text (label)
hLegendComponents = hLegend.EntryContainer.Children;
for isymbol = 1:length(hLegendComponents)
    hLegendIconComponents = hLegendComponents(isymbol).Icon.Transform.Children;
    
    % child 1 = Marker, child 2 = LineStrip
    hLegendMarker = hLegendIconComponents.Children(1);
    
    % Set legend to same transparency as marker
    icolor = length(hLegendComponents) + 1 - isymbol;
    setMarkerColor(hLegendMarker,lMarker(icolor),alpha); % Apply transparency to marker
end

end %function legendMarkers

