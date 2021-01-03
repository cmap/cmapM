% Initial setup of the cmapM repo

% Obtain absolute path to this script
this_path = fileparts(mfilename('fullpath'));

% Environment variable with absolute path to the cmapM base folder
% Referenced within the library using the command cmapmpath
setenv('CMAPMPATH', this_path);
fprintf(1, 'Added cmapM to the search path\n');

% Add appropriate paths to matlab environment
addpath(genpath(this_path));
addpath(genpath(fullfile(this_path, 'bin')));

% Download and unpack assets if not already present
download_cmapm_assets;

% set VDB path
set_vdbpath(fullfile(this_path, 'vdb'));
