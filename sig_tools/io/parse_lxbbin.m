function s = parse_lxbbin(fname, varargin)
% PARSE_LXBBIN Parse an LXB (binary) file
%   LXB = PARSE_LXBBIN(LXBFILE) Returns a sructure (LXB) with fieldnames set 
%   to header labels in row one of LXBFILE.
%
% examples:
% 
% s=parse_lxbbin(mapdir('A1.lxb'), 'analyte_idx','1:100');

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

fprintf('mortar io %s - fname:  %s\n', mfilename, fname);

pnames = {'allfields','analyte_idx'};
dflts = {false, '0:500'};
args = parse_args(pnames, dflts, varargin{:});

lxbutil_classpath = mapdir(fullfile(mortarpath,'ext', 'jars', 'lxb-util.jar'));
dp = javaclasspath;

if ~any(strcmp(lxbutil_classpath, dp))
    fprintf('Adding LXB-parser to classpath\n');
    javaaddpath(lxbutil_classpath)
end

analyte_idx = eval(args.analyte_idx);
analytes = gen_labels(analyte_idx, 'prefix', 'Analyte ', 'zeropad',false);
if length(analytes)<501
    to_filter = true;
    % DefaultDataset loadLXB(String file, String dataColumnName, String[] analytes)
    ds = org.broadinstitute.cancer.io.luminex.LXBUtil.loadLXB(fname, {'RP1'});
    % analyte ids
    s.RID = double(ds.analytes);
    % signal values
    s.RP1 = double(ds.values);
    % filter
    rid_filter = ismember(s.RID, analyte_idx);
    s.RID = s.RID(rid_filter);
    s.RP1 = s.RP1(rid_filter);
else
    to_filter = false;
    % quicker method that returns all analytes
    ds = org.broadinstitute.cancer.io.luminex.LXBUtil.loadLXB(fname, {'RP1'});
    % analyte ids
    s.RID = double(ds.analytes);
    % signal values
    s.RP1 = double(ds.values);
end

if args.allfields
fn = {'DDG', 'DBL', 'DD', 'RP1ATT', 'CL1', 'CL2', 'CL3', 'Aux1', 'TIME'};
    for ii=1:length(fn)
        ds = org.broadinstitute.cancer.io.luminex.LXBUtil.loadLXB(fname, fn{ii});
        v = ds.values;
        if to_filter
            v = v(rid_filter);
        end
        s.(fn{ii}) = v;
    end
end
