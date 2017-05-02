function varargout = printDelimitedLine(li, varargin)
% printDelimitedLine Print a delimited line.
% printDelimitedLine(LI) prints the cell array LI to as a tab-delimited
% string to STDOUT.
% S = printDelimitedLine(LI) returns a char string of the delimited data.
% printDelimitedLine(LI, 'Param1', 'Value1',...)
% Valid options
% 'fid' : prints the line to file handle FID [Default=STDOUT]
% 'dlm' : uses specified delimiter [Default = '\t']
% 'precison' : prints numeric values with specified precision [Default=4]
% 'emptyval' : Used if empty value is found [Default='']
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'--fid'; '--dlm'; '--precision'; '--emptyval'};
dflts = {1; '\t'; inf; ''};

config = struct('name', pnames,...
    'default', dflts,...
    'help', {'File handle to print to'; 'use specified delimiter';
    'print numeric values with specified precision'; 'Default empty value'});
opt = struct('prog', mfilename, 'desc', 'Print a delimited line');

args = cmapm.util.ArgParse.getArgs(config, opt, varargin{:});

%arg = parse_args(pnames, dflts, varargin{:});
nout=nargout;
printline=1;
if isequal(nout,1)
    printline=0;    
end
% backslashes are special
args.dlm = regexprep(args.dlm, '^\\$', '\\\\');   
fmt = ['%s',args.dlm];

if isinf(args.precision)
    numfmt = '%g';
else
    numfmt = sprintf('%%.%df', args.precision);
end

if isnumeric(li) || islogical(li)
    li = cmapm.util.String.num2cellstr(li, 'precision', args.precision);
end
li=li(:);
nl=length(li);
s='';

for ii=1:nl    
    if isempty(li{ii})
        li{ii} = args.emptyval;
    elseif isnumeric(li{ii}) || islogical(li{ii})
%         li{ii} = num2str(li{ii}, numfmt);
        li{ii} = regexprep(num2str(li{ii}(:)', [numfmt, ' ']),' +',',');
    elseif iscell(li{ii})
        li{ii} = cmapm.util.String.printDelimitedLine(li{ii}, 'dlm', '|');
    end    
    if ~isequal(ii,nl)
        s = [s, sprintf(fmt, li{ii})];
    elseif printline
        s = [s, sprintf('%s\n', li{ii})];
    else
        s = [s, sprintf('%s', li{ii})];
    end
end

if ~printline 
    varargout(1) = {s};
else
    fprintf (args.fid,'%s', s);
end
