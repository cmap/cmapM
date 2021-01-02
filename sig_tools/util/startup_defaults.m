% Default settings
fprintf('Setting custom plot preferences\n');

% Set plot defaults
set(0, 'defaultAxesXGrid', 'on');
set(0, 'defaultAxesYGrid', 'on');
set(0, 'defaultAxesZGrid', 'on');
set(0, 'DefaultAxesFontSize', 14);
set(0, 'DefaultAxesFontName', 'Helvetica');
set(0, 'DefaultAxesFontWeight', 'bold');
set(0, 'DefaultTextFontSize', 14);
set(0, 'DefaultUIControlFontSize', 10);
set(0, 'DefaultAxesTickDir', 'out');

% % Initialize the random number generator
% rand('twister', sum(100*clock));
% rand('twister');