function varargout = print_dlm_line(li, varargin)
% PRINT_DLM_LINE Print a delimited line.
% PRINT_DLM_LINE(LI) prints the cell array LI to as a tab-delimited
% string to STDOUT.
% S = PRINT_DLM_LINE(LI) returns a char string of the delimited data.
% PRINT_DLM_LINE(LI, 'Param1', 'Value1',...)
% Valid options
% 'fid' : prints the line to file handle FID [Default=STDOUT]
% 'dlm' : uses specified delimiter [Default = '\t']
% 'precison' : prints numeric values with specified precision [Default=4]

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'fid', 'dlm', 'precision', 'emptyval'};
dflts = {1, '\t', inf, ''};
arg = parse_args(pnames, dflts, varargin{:});
nout=nargout;
printline=1;
if isequal(nout,1)
    printline=0;    
end
fmt = ['%s',arg.dlm];

if isinf(arg.precision)
    numfmt = '%g';
else
    numfmt = sprintf('%%.%df', arg.precision);
end

if isnumeric(li) || islogical(li)
    li = num2cellstr(li, 'precision', arg.precision);
end
li=li(:);
nl=length(li);
s='';

for ii=1:nl    
    if isempty(li{ii})
        li{ii} = arg.emptyval;
    elseif isnumeric(li{ii}) || islogical(li{ii})
%         li{ii} = num2str(li{ii}, numfmt);
        li{ii} = regexprep(num2str(li{ii}, [numfmt, ' ']),' +',',');
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
    varargout(1) ={s};
else
    fprintf (arg.fid,'%s', s);
end
