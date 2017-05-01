function tbl = parse_tbl(tblfile, varargin)
% PARSE_TBL Read a text table.
%   TBL = PARSE_TBL(TBLFILE) Returns a structure TBL with fieldnames set 
%   to header labels in row one of the table.
%
%   TBL = PARSE_TBL(TBLFILE, param1, value1,...) Specifies optional
%   parameters and values. Valid parameters are:
%   'outfmt' <String> Output format. Valid options are
%       {'column','record','dict'}. Default is 'column'
%   'numhead' <Integer> Number of lines to skip. Specifies the row
%   	where the data begins. Assumes the fieldnames are at
%   	(numhead-1)th row. Default is 1. 
%   'lowerhdr' <boolean> Convert header to lowercase. Default is True
%   'detect_numeric' <boolean> Convert numeric fields to
%   	double. Default is True. 
%   'ignore_hash' <boolean> Ignore filds that begin with a
%   	hash. Default is True.


% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'outfmt', 'numhead', 'lowerhdr', ...
'detect_numeric', 'ignore_hash', 'verbose'};
dflts = {'column', 1, true, ...
true, true, true};
arg = parse_args(pnames, dflts, varargin{:});

% guess number of fields
% if the fieldnames have no spaces this should work
dbg(arg.verbose, 'Reading %s\n', tblfile);

first = textread(tblfile, '%s', 1, ...
'delimiter', '\n', 'headerlines', ...
 max(arg.numhead-1, 0));
if arg.numhead>0
    fn = strread(char(first), '%s', 'delimiter', '\t');
else
    tmp = strread(char(first), '%s', 'delimiter', '\t');
    fn = gen_labels(size(tmp,1), 'prefix', 'COL');
end

% convert headers to lowercase
if arg.lowerhdr
    fn = lower(fn);
end
nf=length(fn);
% ignore hash
if arg.ignore_hash
    keep = find(~strncmp('#', fn, 1));
    nkeep = length(keep);
else
    keep = 1:nf;
    nkeep = nf;
end

% fix bad names
fn = validvar(fn, '_');

data = cell(nf, 1);
fmt = repmat('%s', 1, nf);
% no comments allowed
[data{:}] = textread (tblfile, fmt, 'delimiter', '\t',...
'headerlines', max(arg.numhead, 0), 'bufsize', 100000);

for k=1:nkeep
    ii = keep(k);
    % Matlab bug , if last row(s) of last field is empty then data can be
    % less than nrec
    nrec0 = length(data{ii});
    %convert numeric fields to double
    if arg.detect_numeric        
        isnum = all(~isnan(str2double(regexprep(data{ii}(randsample(nrec0, floor(nrec0/20)+1),:),'nan','0'))));
        if isnum
            data{ii} = str2double(data{ii});
        end
    end
    switch(lower(arg.outfmt))
        case 'column'
            tbl.(fn{ii}) = data{ii};
        case 'dict'
            if ii==1
                tbl = bmtk.data.dict;
            end
            if tbl.isKey(fn{ii})
                error ('Duplicate key name found: %s', fn{ii});
            end
            tbl(fn{ii}) = data{ii};
        case 'record'
            if arg.detect_numeric && isnum
                numcell = num2cell(data{ii});
                [tbl(1:nrec0,1).(fn{ii})] = numcell{:};
            else
                [tbl(1:nrec0,1).(fn{ii})] = data{ii}{:};
            end
        case 'table'
            %TODO
%             tbl(1:nrec0, ii) = data{ii};            
        otherwise
            error('Unknown Output format: %s', arg.outfmt)            
    end
end
