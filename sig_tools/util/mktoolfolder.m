function newfolder = mktoolfolder(pfolder, toolname, varargin)
% mktoolfolder Create work and analysis folders with date and timestamps
%   NEWDIR = MKTOOLFOLDER(PARENT, TOOLNAME) creates a folder at
%   PARENT/MMMDD/my_analysis.TOOLNAME.timestamp, where MMM is the 3 letter
%   month code and DD is the 2 digit day number.
%   
%   NEWDIR = mktoolfolder(..., param1, value1,...) specify optional
%   parameters. Valid options are:
%   'prefix' :   String, specify an alternate prefix. Default is
%               'my_analysis'
%   'forcesuffix' :  Boolean, avoid timestamp if possible. Default is true.
%   'overwrite' : Boolean, overwrite existing folder. Default is false

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
% Changes:
% Nov 30,2010,  switched to getargs
%               added overwrite option

pnames = {'prefix', 'forcesuffix', 'overwrite'};
dflts = {'', true, false};
args = parse_args(pnames, dflts, varargin{:});
if isempty(args.prefix)
    args.prefix = 'my_analysis';
end
if (nargin <2)
    error('Must specify parent folder and toolname');
end

outfolder = fullfile(pfolder, lower(datestr(now, 'mmmdd')));
if ~isdirexist(outfolder)
    mkdir (outfolder)
end
    
if args.forcesuffix
    uniquedir = 0;
else
    % try without suffix
    newfolder = fullfile(outfolder, sprintf('%s.%s', args.prefix, toolname));
    if ~args.overwrite
        uniquedir= ~isdirexist(newfolder);
    else
        uniquedir = true;
    end
end
while (~uniquedir)
    pause(3*rand);
    newfolder = genfoldername(outfolder, args.prefix, toolname);
    %is it unique?
    uniquedir = ~isdirexist(newfolder);
end

[success, msg] = mkdir (newfolder);
%fprintf ('%s %d %s\n',newdir, success, msg);



function newfolder = genfoldername(pfolder, prefix, toolname)

% try using the LSF jobid as suffix
jid = get_lsf_jobid;

if isempty(jid)
    % try SGE
    jid = get_sge_jobid;
end

if isempty(jid)
  %create one manually
  jid = sprintf ('%s%d', lower(datestr(now,'YYYYmmddHHMMSS')),round(rand*100));
end

suffix = jid;
newdir = sprintf ('%s.%s.%s',prefix, toolname, suffix);
newfolder = fullfile(pfolder, newdir);
