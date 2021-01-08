%   USEBMTK Add BMTK to the Matlab path
%   USEBMTK Searches for and appends the BMTK folders to the Matlab path.
%   By default the script looks for the BMTK library in the current folder. 
%   The BMTKPATH variable can be set externally to specify an alternate
%   path.
%
%   To automatically include BMTK on startup, add the following lines to
%   your startup.m file:
%
%   % Full path to BMTK
%   BMTKPATH='/path/to/mortar';
%   % Uncomment next line to turn on debugging info
%   %VERBOSE=1
%   run (fullfile(BMTKPATH, 'util/usemortar'));
%
%   Note: You might need to set the following environment variables prior
%   to starting Matlab:
%   MATLABPATH=/path/to/startup.m 
%   MATLAB_USE_USERPATH=1

% If BMTKPATH is not set, default to pwd
if ~exist('BMTKPATH','var')
    [p,f,e] = fileparts(pwd);
    BMTKPATH = p;
end

if exist('VERBOSE', 'var')
    isdebug = VERBOSE;
else
    isdebug = 0;
end
    
%find all folders
if exist(BMTKPATH, 'dir')
    p = genpath(BMTKPATH);
    tp = textscan(p,'%s', 'delimiter', pathsep);
    tp = tp{1};
    % exclude folders
    ex = tp(cellfun(@length, regexp(tp, 'mortar/tools|mortar/doc|mortar/ext|.svn')) > 0);    
    uselist = setdiff(tp, ex);    
    usepath = strcat(uselist, pathsep);
    usepath = strcat(usepath{:});
    cp = textscan(path, '%s', 'delimiter', pathsep);
    currpath = cp{1};    
    addpath(usepath)
    fprintf ('Added BMTK to the path\n');
    mortarver
    if isdebug        
        disp(setdiff(uselist, currpath));
    end
else
    error('BMTK not found at: %s', BMTKPATH);
end
