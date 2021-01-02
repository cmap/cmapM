% How to create a plot with markers that are semi-transparent along with a legend.
%
% A second example of how to create a simple plot containing markers that 
% are semi-transparent. The Matlab code is kept to a minimum.
%
% This example shows how to produce a plot of sine and cosine functions
% containing markers with a blending of symbol face color of alpha = 0.3. 
% A value of alpha = 0.0 produces a transparent face color while a value of
% alpha = 1.0 makes it opaque. The marker size is increased to improve
% appearance. The example plot is written to a file in Portable Network 
% Graphics (PNG) format.
%
% Function Dependencies:
%   rgb
%   rgba
%   setMarkerColor
%   legendMarkers

% Author: Peter A. Rochford
%         Symplectic, LLC
%         www.thesymplectic.com
%         prochford@thesymplectic.com

% Close any previously open graphics windows
close all;

% Set the figure properties (optional)
set(gcf,'units','inches','position',[0,10.0,14.0,10.0]);
set(gcf,'DefaultAxesFontSize',18); % font size of axes text

% Define data values
x = linspace(-pi,pi);
y1 = sin(x); y2 = cos(x);

% Labels for legend
markerLabel = ['Sin'; 'Cos'];

alpha = 0.3;

h1 = plot(x,y1,'b-o','MarkerSize',10);
hm1 = setMarkerColor(h1,'b',alpha); % Apply transparency to marker
hold on;

h2 = plot(x,y2,'r-o','MarkerSize',10);
hm2 = setMarkerColor(h2,'r',alpha); % Apply transparency to marker

% Add legend
hp = [h1; h2];
hLegend=legend(hp,markerLabel,'Location','best');

% Important: The legend function clears marker customizations such as 
% transparency, so restore transparency by re-updating hp.FaceColorData
legendMarkers(hp,hLegend,['b'; 'r'],alpha);

% Write plot to file
writepng(gcf,'marker2.png');
