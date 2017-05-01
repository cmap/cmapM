function s = parse_lxbbin(fname, varargin)
% PARSE_LXBBIN Parse an LXB (binary) file
%   LXB = PARSE_LXBBIN(LXBFILE) Returns a sructure (LXB) with fieldnames set 
%   to header labels in row one of LXBFILE.
%
% examples:
% 
% s=parse_lxbbin('A1.lxb', 'analyte_idx','1:100');

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

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
