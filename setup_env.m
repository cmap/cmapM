% Obtain absolute path to this script
this_path = fileparts(mfilename('fullpath'));

% Add appropriate paths to matlab environment
addpath(genpath(fullfile(this_path, 'bin')));

% Download and unpack assets if not already present
download_cmapm_assets;

% Environment variable with absolute path to the cmapM base folder
% Referenced within the library using the command cmapmpath
setenv('CMAPMPATH', this_path);