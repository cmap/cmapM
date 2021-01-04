function [filttbl, keepidx] = filter_table(tbl, fn, mask, varargin)
% FILTER_TABLE
% filttbl = filter_table(tbl, fn, mask)
%

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

%TODO
% input validation
% masking options

pnames = {'matchtype', 'tblhdr'};
dflts = {'regexpi', ''};
args = parse_args(pnames, dflts, varargin{:});

tbltype = '';
if isstruct(tbl)
    if isequal(length(tbl),1)
        tbltype = 'legacy';
        nrec = length(tbl.(fn{1}));
    else
        tbltype = 'struct';
        nrec = length(tbl);
    end    
elseif isequal(class(tbl), 'containers.Map') || isequal(class(tbl), 'mortar.data.dict')
    tbltype = 'dict';
    n = cellfun(@length, tbl.values);
    if ~all(n == n(1))
        error('All keys should have the same number of elements');
    else
        nrec = n(1);
    end
elseif iscell(tbl) && iscell(args.tblhdr)
    tbltype = 'cell';
    nrec = size(tbl, 1);
    hdmap = containers.Map(args.tblhdr, 1:length(args.tblhdr));
    
elseif isfileexist(tbl)
    tbltype = 'struct';
    tblfile = tbl;
    tbl = parse_record(tblfile, false);
    nrec = length(tbl);
else
    error('File not found: %s', tbl);
end

keep = true(nrec, 1);
nfilt = length(fn);

for ii=1:nfilt
    switch(tbltype)
        case 'legacy'
            keep = keep & (do_match(tbl.(fn{ii}), mask{ii}, args.matchtype));
        case 'dict'
            keep = keep & (do_match(tbl(fn{ii}), mask{ii}, args.matchtype));
        case 'struct'
            keep = keep & (do_match({tbl.(fn{ii})}, mask{ii}, args.matchtype))';
        case 'cell'
            keep = keep & do_match(tbl(:, hdmap(fn{ii})), mask{ii}, args.matchtype);
        otherwise
            error ('Unknown table type');
    end
end
keepidx = find(keep);

switch(tbltype)
    case 'legacy'
        f = fieldnames(tbl);
        filttbl=([]);
        for ii=1:length(f)
            filttbl.(f{ii}) = tbl.(f{ii})(keep);
        end
    case 'dict'
        f = tbl.keys;
        filttbl=containers.Map;
        for ii=1:length(f)
            v = tbl(f{ii});
            filttbl(f{ii}) = v(keep);
        end
    case 'struct'
        filttbl = tbl(keep);
    case 'cell'
        filttbl = tbl(keep,:);
    otherwise
        error ('Unknown table type');
end

end

function ismatch = do_match(cstr, search_string, search_type)
switch search_type
    % case insensitive partial match
    case 'regexpi'
        ismatch = (cellfun(@length, regexpi(cstr, search_string))>0);
    %case sensitive partial match
    case 'regexp'
        ismatch = (cellfun(@length, regexp(cstr, search_string))>0);        
    % exact
    case 'exact'        
        ismatch = strcmp(cstr, search_string);
end
end