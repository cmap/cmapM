function s = parse_lxbbin(fname, varargin)
% PARSE_LXBBIN Parse a binary luminex LXB file
%   LXB = PARSE_LXBBIN(LXBFILE) Returns a sructure (LXB) with data from all 
%   detected beads in a single LXB file with the following fields:
%   'RID', The identity of each bead [1-500], unassigned beads have RID=0
%   'RP1', corresponding fluorescent intensities of each bead
% 
%    LXB = PARSE_LXBBIN(LXBFILE, 'param1', value1,...) Specify optional
%    parameter/value pairs:
%
%   'allfields' boolean, returns additional experimental 
%       parameters from the LXB file if true. Default is false.
%
% Examples:
% 
% S=PARSE_LXBBIN('A1.lxb')

pnames = {'allfields'};
dflts = {false};
arg = parse_args(pnames, dflts, varargin{:});


full_path = mfilename('fullpath');
this_path = fileparts(full_path);
lxbutil_classpath = fullfile(this_path, 'lxb-util.jar');
dp = javaclasspath;

if ~any(strcmp(lxbutil_classpath, dp))
    fprintf('Adding Java LXB parser to classpath\n');
    javaaddpath(lxbutil_classpath)
end

ds = org.broadinstitute.cancer.io.luminex.LXBUtil.loadLXB(fname, {'RP1'});
% analyte ids
s.RID = double(ds.analytes);
% signal values
s.RP1 = double(ds.values);

if arg.allfields
fn = {'DDG', 'DBL', 'DD', 'RP1ATT', 'CL1', 'CL2', 'CL3', 'Aux1', 'TIME'};
    for ii=1:length(fn)
        ds = org.broadinstitute.cancer.io.luminex.LXBUtil.loadLXB(fname, fn{ii});
        s.(fn{ii}) = ds.getArray;
    end
end
end
