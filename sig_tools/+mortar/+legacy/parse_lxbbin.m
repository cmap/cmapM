% PARSE_LXBBIN Parse an LXB (binary) file
%   LXB = PARSE_LXBBIN(LXBFILE) Returns a sructure (LXB) with fieldnames set 
%   to header labels in row one of LXBFILE.
%
% examples:
% 
% s=wk_parse_lxb(mapdir('/xchip/cogs/pipeline/lxb/DEV_1023_P3_lxb/A1.lxb'),
% 'analyte_idx','1:100');

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function s = parse_lxbbin(fname, varargin)

pnames = {'allfields','analyte_idx'};
dflts = {false, '0:500'};
arg = parse_args(pnames, dflts, varargin{:});

gene_classpath = mapdir('/cmap/tools/sig_tools/GENE-E.jar');
dp = javaclasspath;

if isempty(strmatch(gene_classpath, dp))
    fprintf('Adding GENE-E to classpath\n');
    javaaddpath(gene_classpath)
end

analyte_idx = eval(arg.analyte_idx);
% analytes = strrep(strcat('Analyte:',strtrim(num2cellstr(analyte_idx))),':', ' ');
analytes = gen_labels(analyte_idx, '-prefix', 'Analyte ','-zeropad',false);
if length(analytes)<501
    % DefaultDataset loadLXB(String file, String dataColumnName, String[] analytes)
    ds = org.broadinstitute.cancer.io.lxb.LXBUtil.loadLXB(fname, {'RP1'}, analytes);
    % analyte ids
    s.RID = str2double(strrep(cell(org.broadinstitute.cancer.matrix.DatasetUtil.getRowNames(ds)),'Analyte ',''));
    % signal values
    s.RP1 = ds.getArray;
else
    % quicker method that returns all analytes
    ds = org.broadinstitute.cancer.io.lxb.LXBUtil.loadLXBQuick(fname, {'RP1'});
    % analyte ids
    s.RID = double(ds.analytes);
    % signal values
    s.RP1 = double(ds.data);
end

if arg.allfields
fn = {'DDG', 'DBL', 'DD', 'RP1ATT', 'CL1', 'CL2', 'CL3', 'Aux1', 'TIME'};
    for ii=1:length(fn)
        ds = org.broadinstitute.cancer.io.lxb.LXBUtil.loadLXB(fname, fn{ii}, analytes);
        s.(fn{ii}) = ds.getArray;
    end
end
