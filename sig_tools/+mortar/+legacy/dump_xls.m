function dump_xls(xlsfile, varargin)
% DUMP_XLS Extract Data tables from Microsoft Excel worksheets.
%   DUMP_XLS(XLFILE) Extracts all worksheets from XLFILE and writes them as
%   tab-delimited text files
%   DUMP_XLS(XLFILE, 'out', OUTPATH) saves files to OUTPATH
%

pnames = {'out'};
dflts = {pwd};
args = parse_args(pnames, dflts, varargin{:});

wksheet = parse_xls(xlsfile, 'ls', true);

for ii=1:length(wksheet); 
    data = parse_xls(xlsfile, 'wksheet', wksheet(ii).idx); 
    mktbl(fullfile(args.out, wksheet(ii).name), data);
end

end