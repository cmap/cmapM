% Matlab startup file that adds Mortar to the Matlab path and setup
% defaults. 
%
% To use copy this file to $HOME/matlab/startup.m and
% restart Matlab. If installed correctly, the Mortar library should
% be available in your workspace. 


% use only if not in MCR
if ~isdeployed
%get last working directory, default to current
%cwd = getpref('Startup', 'dir', pwd);
cwd = pwd;

% Add Mortar to path
MORTARPATH='/cmap/tools/mortar';
% Uncomment next line to turn on debugging info
VERBOSE=1
run (fullfile(MORTARPATH, 'util/usemortar'));

% restore last work folder
cd (cwd);

% Add Mongo jar to dynamic path
add_mongo_jar(VERBOSE);

% plot preferences (in bmtk/util/)
startup_defaults

% Turn on logging
%DIARY_PATH='/path/to/log';
%diary (fullfile(DIARY_PATH, sprintf('%s.txt',date)));

% Set debugging options
% dbstop if error
end
