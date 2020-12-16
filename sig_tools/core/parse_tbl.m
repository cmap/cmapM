function [tbl, isnum, orig_fn] = parse_tbl(tblfile, varargin)
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
%
%   'delimiter' <String> Field delimter. Default is '\t'
%
%   'string_format' <String> string format specifier. Default is '%q'.
%       which removes quotations from input data. Specify '%s' to avoid 
%       this behavior.
%
%   'string_deblank' <boolean> deblank strings if true. Default is false
%
%   [TBL, ISNUM] = PARSE_TBL(TBLFILE, param1, value1,...) returns a column
%   boolean vector of length matching the number of columns in the table.


% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'outfmt', 'numhead', 'lowerhdr', ...
    'detect_numeric', 'ignore_hash', 'verbose',...
    'ignore_type', 'comment_style', 'delimiter',...
    'string_format', 'string_deblank'};
dflts = {'column', 1, true, ...
    true, true, true,...
    '', '#', '\t',...
    '%q', false};
args = parse_args(pnames, dflts, varargin{:});

if isfileexist(tblfile)
    % guess number of fields
    % if the fieldnames have no spaces this should work
    dbg(args.verbose, 'Reading %s\n', tblfile);
    
    fid = fopen(tblfile, 'r');
    first = textscan(fid, args.string_format, 1, ...
        'delimiter', '\n', 'headerlines', ...
        max(args.numhead-1, 0));
    if args.numhead>0
        fn = textscan(char(first{1}), args.string_format, 'delimiter', args.delimiter);
        fn = fn{1};
        dup = duplicates(fn);
        if ~isempty(dup)
            warning('PARSE_TBL:duplicateHeaders',...
                'Header has duplicate fields, de-duplicating by appending an integer suffix');
            disp(dup);
            fn = deduplicate_str(fn);
        end
    else
        tmp = textscan(char(first{1}), args.string_format, 'delimiter', args.delimiter);
        fn = gen_labels(size(tmp{1}, 1), 'prefix', 'COL');
        % rewind to beginning
        fseek(fid, 0, 'bof');
    end
    
    % Original header names
    orig_fn = fn;

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
    
    
    fmt = repmat(args.string_format, 1, nf);
    % no comments allowed
    % data = cell(nf, 1);
    % [data{:}] = textread (tblfile, fmt, 'delimiter', '\t',...
    % 'headerlines', max(args.numhead, 0), 'bufsize', 100000);
    
    data = textscan (fid, fmt, 'Delimiter', args.delimiter);
    
    fclose (fid);
    % only keep lines not beginning with a comment field
    % note commentstyle in textscan checks all fields not just the first one.
    keep_lines = cellfun(@isempty,regexp(data{keep(1)}, ...
        sprintf('^%s', args.comment_style)));
    
    % if args.detect_numeric
    %     data = detect_numeric(data);
    % end
    ignore_type = list2dict(args.ignore_type);
    isnum = false(nkeep, 1);
    for k=1:nkeep
        ii = keep(k);
        data{ii} = data{ii}(keep_lines);
        % Matlab bug , if last row(s) of last field is empty then data can be
        % less than nrec
        nrec0 = length(data{ii});
        if args.string_deblank
            data{ii} = str_deblank(data{ii});
        end
        %convert numeric fields to double
        if args.detect_numeric && ~isKey(ignore_type, fn{ii})
            [data{ii}, isnum(k)] = detect_numeric(data{ii});
            
            if isnum(k) && ismember(lower(args.outfmt), {'column', 'dict'})
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
elseif isstruct(tblfile)
    tbl = tblfile;
    orig_fn = fieldnames(tbl);
    nout = nargout;
    if nout >1 || args.detect_numeric
        [isnum, tbl] = mortar.util.DataType.detectTableNumericFields(tbl, args.detect_numeric);
    end
else
    error('Invalid input for parse_tbl. File not found or incorrect type (expected char or struct) for tblfile input argument.  tblfile:  %s  class(tblfile):  %s', ...
        tblfile, class(tblfile))
end
