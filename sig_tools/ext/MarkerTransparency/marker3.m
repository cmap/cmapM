% How to create plots with markers of varying transparency with legends.
%
% A third example of how to create plots containing markers that have
% varying transparency.
%
% This example shows how to produce a plot of sine and cosine functions
% containing markers with a blending of symbol face color of alpha = 0, 
% 0.3, and 1.0. A value of alpha = 0.0 produces a transparent face color 
% while a value of alpha = 1.0 makes it opaque. The purpose of this example
% is to show the changes in the markers as the transparency is varied. The
% example plot is written to a file in Portable Network Graphics (PNG) 
% format.
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
angle = linspace(-180,180,40);
x = deg2rad(angle);
y1 = sin(x); y2 = cos(x);

% Labels for legend
markerLabel = ['Sin'; 'Cos'];

% Colors for functions
color = ['b'; 'r'];

% Create first of three subplots where markers are opaque 
subplot(3,1,1);

alpha = 1.0;

h1 = plot(angle,y1,[color(1) '-o'],'MarkerSize',10);
hm1 = setMarkerColor(h1,color(1),alpha); % Apply transparency to marker
hold on;

h2 = plot(angle,y2,[color(2) '-o'],'MarkerSize',10);
hm2 = setMarkerColor(h2,color(2),alpha); % Apply transparency to marker

% Add legend
hp = [h1; h2];
hLegend=legend(hp,markerLabel,'Location','northwest');

% Important: The legend function clears marker customizations such as 
% transparency, so restore transparency by re-updating hp.FaceColorData
legendMarkers(hp,hLegend,color,alpha);

% Make the plot look nicer
xlim([angle(1) angle(end)]);
ylabel('f(\theta)');

% Create second of three subplots where markers are semi-transparent 
subplot(3,1,2);

alpha = 0.3;

h1 = plot(angle,y1,[color(1) '-o'],'MarkerSize',10);
hm1 = setMarkerColor(h1,color(1),alpha); % Apply transparency to marker
hold on;

h2 = plot(angle,y2,[color(2) '-o'],'MarkerSize',10);
hm2 = setMarkerColor(h2,color(2),alpha); % Apply transparency to marker

% Add legend
hp = [h1; h2];
hLegend=legend(hp,markerLabel,'Location','northwest');

% Important: The legend function clears marker customizations such as 
% transparency, so restore transparency by re-updating hp.FaceColorData
legendMarkers(hp,hLegend,color,alpha);

% Make the plot look nicer
xlim([angle(1) angle(end)]);
ylabel('f(\theta)');


% Create third of three subplots where markers are transparent 
subplot(3,1,3);

alpha = 0.0;

h1 = plot(angle,y1,[color(1) '-o'],'MarkerSize',10);
hm1 = setMarkerColor(h1,color(1),alpha); % Apply transparency to marker
hold on;

h2 = plot(angle,y2,[color(2) '-o'],'MarkerSize',10);
hm2 = setMarkerColor(h2,color(2),alpha); % Apply transparency to marker

% Add legend
hp = [h1; h2];
hLegend=legend(hp,markerLabel,'Location','northwest');

% Important: The legend function clears marker customizations such as 
% transparency, so restore transparency by re-updating hp.FaceColorData
legendMarkers(hp,hLegend,color,alpha);

% Make the plot look nicer
xlim([angle(1) angle(end)]);
xlabel('\theta (degrees)');
ylabel('f(\theta)');

% Write plot to file
writepng(gcf,'marker3.png');
