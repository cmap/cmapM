function newfolder = mkworkfolder(pfolder, prefix, varargin)
% MKWORKFOLDER Create work and analysis folders with date and timestamps
%   NEWDIR = MKWORKFOLDER creates a folder in the current working
%   directory at PWD/MMMDD, where MMM is the 3 letter month code and DD is
%   the 2 digit day number.
%   
%   NEWDIR = MKWORKFOLDER(PARENT) creates a folder under PARENT.
%
%   NEWDIR = MKWORKFOLDER(PARENT, PREFIX) creates an analysis subfolder
%   under parent at PARENT/PREFIX_HHMMSS, where HH, MM and SS are the
%   current hour, minute and seconds returned by NOW.
%   NEWDIR = MKWORKFOLDER(PARENT, PREFIX, FORCESUFFIX) Forces suffix
%   generation if FORCESUFFIX is true, otherwise attempts to create folder
%   without suffix first.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
% Changes:
% Nov 30,2010,  switched to getargs
%               added overwrite option
pnames = {'forcesuffix', 'overwrite'};
dflts = {true, false};
arg = parse_args(pnames, dflts, varargin{:});
% s=init_rand_state;

if (~exist('pfolder','var'))
   pfolder = pwd;
end
if (~exist('prefix','var'))
    prefix = 'my_analysis';
end
% seems to fix race condition
% pause(1);

if ~isdirexist(pfolder)
    mkdir (pfolder)
end
    
if arg.forcesuffix
    uniquedir = 0;
else
    % try without suffix
    newfolder = fullfile(pfolder, prefix);
    if ~arg.overwrite
        uniquedir= ~isfileexist(newfolder, 'dir');
    else
        uniquedir = true;
    end
end
while (~uniquedir)
    pause(3*rand);
    newfolder = genfoldername(pfolder, prefix);
    %is it unique?
    uniquedir = ~isfileexist(newfolder,'dir');
end

[success, msg] = mkdir (newfolder);
%fprintf ('%s %d %s\n',newdir, success, msg);



function newfolder = genfoldername(pfolder, prefix)

% try using the LSF jobid as suffix
jid = get_lsf_jobid;
if ~isempty(jid)
  suffix=jid;
else
  %create one manually
  suffix = sprintf ('%s%d', lower(datestr(now,'YYYY.mm.dd.HHMMSS')),round(rand*100));
end

newdir = sprintf ('%s.%s',prefix, suffix);
newfolder = fullfile(pfolder, newdir);
