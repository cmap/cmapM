function tbl = parse_tbl(tblfile, varargin)
% PARSE_TBL Read a text table.
%   TBL = PARSE_TBL(TBLFILE) Returns a structure TBL with fieldnames set 
%   to header labels in row one of the table.
%
%   TBL = PARSE_TBL(TBLFILE, param1, value1,...) Specifies optional
%   parameters and values. Valid parameters are:
%
%   'outfmt' <String> Output format. Valid options are
%       {'column','record','dict'}. Default is 'column'
%
%   'numhead' <Integer> Number of lines to skip. Specifies the row
%   	where the data begins. Assumes the fieldnames are at
%   	(numhead-1)th row. Default is 1. 
%
%   'lowerhdr' <boolean> Convert header to lowercase. Default is True.
%
%   'detect_numeric' <boolean> Convert numeric fields to
%   	double. Default is True. 
%
%   'ignore_hash' <boolean> Ignore fields that begin with a
%   	hash. Default is True.
%
%   'comment_style' <String> Symbol(s) designating lines to ignore. Specify
%       a single string (such as '%') to ignore characters following the
%       string on the same line. Specify a cell array of two strings (such
%       as {'/*', '*/'}) to ignore characters between the strings. Default
%       is '#'

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'outfmt', 'numhead', 'lowerhdr', ...
    'detect_numeric', 'ignore_hash', 'verbose',...
    'ignore_type', 'comment_style'};
dflts = {'column', 1, true, ...
    true, true, true,...
    '', '#'};
args = parse_args(pnames, dflts, varargin{:});

assert(isfileexist(tblfile), 'File not found');

% guess number of fields
% if the fieldnames have no spaces this should work
dbg(args.verbose, 'Reading %s\n', tblfile);

fid = fopen(tblfile, 'rt');
first = textscan(fid, '%s', 1, ...
'delimiter', '\n', 'headerlines', ...
 max(args.numhead-1, 0));
if args.numhead>0
    fn = textscan(char(first{1}), '%s', 'delimiter', '\t');
    fn = fn{1};
    dup = duplicates(fn);
    if ~isempty(dup)
        warning('PARSE_TBL:duplicateHeaders',...
            'Header has duplicate fields, keeping the one(s) that occur(s) last');
        disp(dup);
    end
else
    tmp = textscan(char(first{1}), '%s', 'delimiter', '\t');
    fn = gen_labels(size(tmp{1}, 1), 'prefix', 'COL');
    % rewind to beginning
    fseek(fid, 0, 'bof');
end

% convert headers to lowercase
if args.lowerhdr
    fn = lower(fn);
end
nf=length(fn);
% ignore hash
if args.ignore_hash
    keep = find(~strncmp('#', fn, 1));
    nkeep = length(keep);
else
    keep = 1:nf;
    nkeep = nf;
end

% fix bad names
fn = validvar(fn, '_');


fmt = repmat('%s', 1, nf);
% no comments allowed
% data = cell(nf, 1);
% [data{:}] = textread (tblfile, fmt, 'delimiter', '\t',...
% 'headerlines', max(args.numhead, 0), 'bufsize', 100000);

data = textscan (fid, fmt, 'Delimiter', '\t',...
    'BufSize', 100000);

fclose (fid);
% only keep lines not beginning with a comment field
% note commentstyle in textscan checks all fields not just the first one.
keep_lines = cellfun(@isempty,regexp(data{keep(1)}, ...
    sprintf('^%s', args.comment_style)));

% if args.detect_numeric
%     data = detect_numeric(data);
% end
ignore_type = list2dict(args.ignore_type);

for k=1:nkeep
    ii = keep(k);
     data{ii} = data{ii}(keep_lines);
    % Matlab bug , if last row(s) of last field is empty then data can be
    % less than nrec
    nrec0 = length(data{ii});
    %convert numeric fields to double
    if args.detect_numeric && ~isKey(ignore_type, fn{ii})   
        [data{ii}, isnum] = detect_numeric(data{ii});
        
        if isnum && ismember(lower(args.outfmt), {'column', 'dict'})
            % convert cell array  to vector for these formats
            data{ii} = cell2mat(data{ii});
        end
    end

    switch(lower(args.outfmt))
        case 'column'
            tbl.(fn{ii}) = data{ii};
        case 'dict'
            if ii==1
                tbl = containers.Map;
            end
            if tbl.isKey(fn{ii})
                error ('Duplicate key name found: %s', fn{ii});
            end
            tbl(fn{ii}) = data{ii};
        case 'record'
            [tbl(1:nrec0,1).(fn{ii})] = data{ii}{:};
        case 'table'
            %TODO
%             tbl(1:nrec0, ii) = data{ii};            
        otherwise
            error('Unknown Output format: %s', args.outfmt)            
    end
end
