%   USEMORTAR Add MORTAR to the Matlab path
%   USEMORTAR Searches for and appends the MORTAR folders to the Matlab path.
%   By default the script looks for the MORTAR library in the current folder. 
%   The MORTARPATH variable can be set externally to specify an alternate
%   path.
%
%   To automatically include MORTAR on startup, add the following lines to
%   your startup.m file:
%
%   % Full path to MORTAR
%   MORTARPATH='/path/to/mortar';
%   % Uncomment next line to turn on debugging info
%   %VERBOSE=1
%   run (fullfile(MORTARPATH, 'util/usemortar'));
%
%   Note: You might need to set the following environment variables prior
%   to starting Matlab:
%   MATLABPATH=/path/to/startup.m 
%   MATLAB_USE_USERPATH=1

% If MORTARPATH is not set, default to pwd
if ~exist('MORTARPATH','var')
    [p,f,e] = fileparts(pwd);
    MORTARPATH = p;
end

if exist('VERBOSE', 'var')
    isdebug = VERBOSE;
else
    isdebug = 0;
end
    
%find all folders
if exist(MORTARPATH, 'dir')
    p = genpath(MORTARPATH);
    tp = textscan(p,'%s', 'delimiter', pathsep);
    tp = tp{1};
    % exclude folders
    ex = tp(cellfun(@length, regexp(tp, 'config|mortar/ext|\.svn|\.git|mortar/scratch|CompiledCode|js|tests')) > 0);
    % add xunit
    xunit = tp(cellfun(@length, regexp(tp, '/ext/matlab_xunit/xunit'))>0)
    if isempty(xunit)
        fprintf('WARNING: could not find xunit, will not load\n')
    end

    % add yaml
    yaml = tp(cellfun(@length, regexp(tp, '/ext/yamlmatlab$'))>0)
    if isempty(yaml)
        fprintf('WARNING:  could not find yaml, will not load\n')
    end

    % add plot2svg
    p2svg = tp(cellfun(@length, regexp(tp, '/ext/plot2svg$'))>0)
    if isempty(p2svg)
        fprintf('WARNING:  could not find p2svg, will not load\n')
    end

    % add jsonlab
    jsonlab = tp(cellfun(@length, regexp(tp, '/ext/jsonlab$'))>0)
    if isempty(jsonlab)
        fprintf('WARNING:  could not find jsonlab, will not load\n')
    end
    
    ex = setdiff(ex, [yaml; p2svg; jsonlab]);
    uselist = setdiff(tp, ex);
    usepath = strcat(uselist, pathsep);
    usepath = strcat(usepath{:});
    cp = textscan(path, '%s', 'delimiter', pathsep);
    currpath = cp{1};
    addpath(usepath)
    fprintf ('Added MORTAR to the path\n');
    mortarver
    if isdebug
        disp(setdiff(uselist, currpath));
    end
else
    error('MORTAR not found at: %s', MORTARPATH);
end
