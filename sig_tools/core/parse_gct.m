function ds = parse_gct(varargin)
% PARSE_GCT Read a Broad GCT file
%   DS = PARSE_GCT(FNAME)
%   Reads a v1.2 or v1.3 GCT file FNAME and returns a structure with the
%   following fields:
%       mat: Numeric data matrix [RxC]
%       rid: Cell array of row ids
%       rhd: Cell array of row annotation fieldnames
%       rdict: Dictionary of row annotation fieldnames to indices
%       rdesc: Cell array of row annotations
%       cid: Cell array of column ids
%       chd: Cell array of column annotation fieldnames
%       cdict: Dictionary of column annotation fieldnames to indices
%       cdesc: Cell array of column annotations
%       version: GCT version string
%       src: Source filename
%
%   DS = PARSE_GCT(FNAME, param, value,...) Specify optional parameters.
%   Valid parameters are:
%       'class': Sets the class of the data matrix. Valid classes include:
%                'double', 'single', 'int8', 'uint8', 'int16', 'uint16',
%               'int32', 'uint32', 'int64', 'uint64' and 'logical'.
%                See CLASS for descriptions.
%
%       'detect_numeric': Converts numeric annotation fields in rdesc and
%                         cdesc to numbers
%

% Copyright (c) 2011,2012 Broad Institute of MIT and Harvard.
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

% CAVEAT: this code does not handle missing values
% 2/22/2008, GE changed to single precision to save memory
% 11/22/2010, version #1.3 support for sample descriptions
%   Now returns file, version info
% 30/09/2011, Multifile support, row and column dictionaries
% 27/06/2012, lowercase rhd and chd

% pnames = {'class', 'lowmem', 'detect_numeric',...
%           'checkid', 'verbose', 'rid', 'cid', 'has_missing_data',...
%            '--row_filter', '--column_filter'};
% dflts =  {'single', false, true,...
%           true, true, '', '', false,...
%           '', ''};
% arg = parse_args(pnames, dflts, varargin{:});
[args, help_flag] = readArgs(varargin{:});

if ~help_flag
    validclass={'double', 'single', 'int8', 'uint8', 'int16', 'uint16',...
        'int32', 'uint32', 'int64', 'uint64', 'logical'};
    
    %check if valid cc type
    if ~isvalidstr(args.class, validclass)
        error('Invalid classname: %s\n', args.class);
    end
    
    %required fields
    reqfn = {'mat', 'rid', 'rdesc', 'rhd', 'cid', 'cdesc', 'chd'};
    
    if isstruct(args.fname)
        fn = fieldnames(args.fname);
        if isempty(setdiff(reqfn, fn))
            ds = ds_slice(args.fname, 'rid', args.rid, 'cid', args.cid,...
                'row_filter', args.row_filter,...
                'column_filter', args.column_filter,...
                'checkid', args.checkid);
            %clear('fname');
        else
            setdiff(reqfn, fn);
            error('Struct input does not have required fields');
        end
    elseif isfileexist(args.fname)
        [dsfile, nds] = parse_filename(args.fname);
        for ii=1:nds
            [~, ~, e] = fileparts(dsfile{ii});
            % if matfile , load it
            if strcmpi('.mat', e)
                fn = who('-file', dsfile{ii});
                if isempty(setdiff(reqfn, fn))
                    ds(ii) = load(dsfile{ii});
                else
                    setdiff(reqfn. fn);
                    error('.mat file does not have required fields');
                end
            else
                ds(ii) = parse_gct_generic(dsfile{ii}, args);
            end
        end
    else
        error('mortar:parse_gct2:InvalidInput', 'InvalidInput')
    end
end
end

% generic gct parser for versions (1.2, 1.3)
function ds = parse_gct_generic(fname, args)
ds = struct('mat', [],...
    'rid', '',...
    'rhd', '',...
    'rdesc', '',...
    'rdict', list2dict(''),...
    'cid', '',...
    'chd', '',...
    'cdesc', '',...
    'cdict', list2dict(''),...
    'version', '',...
    'src', fname);

%max number of lines per read block
maxline = 4000;
%max buffer size (bytes)
maxbuf = 100000;
fid = fopen(fname, 'rt');
ds.version = strtrim(fgetl(fid));
% second line
l2 = fgetl(fid);
% number of features(genes) and samples
x = textscan(l2, '%f', 4, 'delimiter','\t');
nr = x{1}(1);
nc = x{1}(2);
% third line
l3 = fgetl(fid);
x3 = textscan(l3, '%s', 'delimiter', '\t');
% row desc keys
switch(ds.version)
    case '#1.2'
        rowkeys = {'desc'};
        nrdesc = 1;
        ncdesc = 0;
    case '#1.3'
        nrdesc = x{1}(3);
        ncdesc = x{1}(4);
        rowkeys = lower(x3{1}(1+(1:nrdesc)));
    otherwise
        error('Unknown version: %s', ds.version)
end

% col names
ds.cid = strtrim(x3{1}((2 + nrdesc):end));
check_dup_id(ds.cid, args.checkid);

nsamples = length(ds.cid);

% column descriptor row(s)
emptyval = {''};
ds.chd = cell(ncdesc, 1);
ds.cdesc = cell(nc, ncdesc);
for ii=1:ncdesc
    line = fgetl(fid);
    x = textscan(line, '%s', 'delimiter', '\t');
    %sample desc
    %     ds.coldesc(x{1}{1}) = x{1}((2+nrdesc):end);
    % empty value fix
    ds.chd{ii} = lower(x{1}{1});
    ds.cdesc(:, ii) = [x{1}(1+nrdesc+(1:nc)); emptyval(1:(nc+nrdesc+1 - length(x{1})))];
end
ds.cdict = list2dict(ds.chd);
% close file descriptor
fclose(fid);
% row name
ds.rid = cell(nr, 1);
if ~isempty(rowkeys)
    ds.rhd = rowkeys;
    % create dictionaries for row annotations
    ds.rdict = list2dict(ds.rhd);
    % row descriptors
    ds.rdesc = cell(nr, nrdesc);
end
switch(args.class)
    case {'double','single'}
        ds.mat = zeros(nr, nc, args.class);
        classfmt = '%f';
    case {'int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
        ds.mat = zeros(nr, nc, args.class);
        classfmt = '%d';
    case {'logical'}
        ds.mat = false(nr, nc);
        classfmt = '%d';
end

if args.has_missing_data
    fmt = [repmat('%s', 1, 1+nrdesc), repmat('%s', 1, nsamples)];
else
    fmt = [repmat('%s', 1, 1+nrdesc), repmat(classfmt, 1, nsamples)];
end

dbg (args.verbose, 'Reading %s [%dx%d]', fname, nr, nc);
dbg(args.verbose, 'class:%s', args.class);

%read line by line
if (args.lowmem)
    % TODO
    disp('TODO: lowmem support');
    %     x=cell(1, nsamples+2);
    %     for r=1:nr;
    %         [x{:}] = strread(fgetl(fid), fmt, 'delimiter', '\t');
    %         gn{r} = char(x{1});
    %         gd{r} = char(x{2});
    %         ge(r,:) = [x{3:end}];
    %     end
else
    %line count
    lc = nr;
    iter = ceil(lc / maxline);
    lctr = 0;
    skip = 3 + ncdesc;
    fid = fopen(fname,'rt');
    
    for l=1:iter
        if isequal(l, 1)
            x = textscan(fid, fmt, maxline, 'delimiter', '\t', ...
                'headerlines', skip);
        else
            x = textscan(fid, fmt, maxline, 'delimiter', '\t');
        end
        
        if (lctr+maxline > lc)
            nrows = lc-lctr;
        else
            nrows = maxline;
        end
        
        row_count = cellfun(@length, x);
        assert(all(abs(row_count-nrows)<eps),...
            '%d rows expected, %d-%d read, missing data? Try --has_missing_data',...
            nrows, min(row_count), max(row_count))
        % row name
        ds.rid(lctr+(1:nrows)) = strtrim(x{1});
        
        % row descriptor(s)
        for ii=1:nrdesc
            ds.rdesc(lctr+(1:nrows), ii) = x{1+ii};
        end
        if args.has_missing_data
            ds.mat(lctr+(1:nrows),:) = str2double([x{(2+nrdesc):end}]);
        else
            ds.mat(lctr+(1:nrows),:) = [x{(2+nrdesc):end}];
        end
        
        lctr = l*maxline;
        %dbg(args.verbose, 'read:%d/%d', min(lctr, lc), lc);
    end
end
check_dup_id(ds.rid, args.checkid);
dbg(args.verbose, 'Done.');
fclose(fid);

if args.skip_annot
    dbg(args.verbose, 'Removing metadata.');
    ds = ds_strip_meta(ds);
end

if args.detect_numeric
    if ncdesc
        ds.cdesc = detect_numeric(ds.cdesc);
    end
    if nrdesc
        ds.rdesc = detect_numeric(ds.rdesc);
    end
end

ds = ds_slice(ds, 'rid', args.rid, 'cid', args.cid,...
    'row_filter', args.row_filter,...
    'column_filter', args.column_filter,...
    'checkid', args.checkid);

end
function [args, help_flag] = readArgs(varargin)
pnames = {'fname',...
    '--rid',...
    '--cid',...
    '--row_filter',...
    '--column_filter',...
    '--detect_numeric',...
    '--checkid',...
    '--class',...
    '--lowmem',...
    '--verbose',...
    '--has_missing_data',...
    '--skip_annot'};

dflts =  {'',...
    '',...
    '',...
    '',...
    '',...
    true,...
    true,...
    'single',...
    false,...
    true,...
    false,...
    false};
help_str = {'GCT file or data structure',...
    'Cell array or GRP file specifying a subset of row identifiers to extract',...
    'Cell array or GRP file specifying a subset of column identifiers to extract',...
    'GMT or GMX file or structure specifying rules to filter rows on. See parse_filter for details on specifying the rules',...
    'GMT or GMX file or structure specifying rules to filter columns on. See parse_filter for details on specifying the rules',...
    'Boolean, If true identifies numeric meta-data and casts them to the appropriate data type',...
    'Boolean, if true validates if row and column ids are unique',...
    'String representing a valid numeric class, Casts the matrix data to the specified class',...
    'Boolean, If true reduces memory footprint',...
    'Boolean, If true prints verbose messages',...
    'Boolean if true tries to handle missing data',...
    'Boolean, If true returns only row and column ids without other meta-data or the data matrix',...
    };
config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename,...
    'desc', 'Read a GCT(x) file and returns a data structure.',...
    'undef_action', 'warn');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

end