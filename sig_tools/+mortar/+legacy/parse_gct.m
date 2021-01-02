function ds = parse_gct(fname,varargin)
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
%                'int32', 'uint32', 'int64', 'uint64' and 'logical'. 
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


pnames = {'class', 'lowmem', 'detect_numeric', 'checkid', 'verbose'};
dflts =  {'single', false, true, true, true};
arg = mortar.legacy.parse_args(pnames, dflts, varargin{:});
validclass={'double', 'single', 'int8', 'uint8', 'int16', 'uint16',...
    'int32', 'uint32', 'int64', 'uint64', 'logical'};

%check if valid cc type
if ~mortar.legacy.isvalidstr(arg.class, validclass)
    error('Invalid classname: %s\n', arg.class);
end

%required fields
reqfn = {'mat', 'rid', 'rdesc', 'rhd', 'cid', 'cdesc', 'chd'};

if isstruct(fname)
    fn = fieldnames(fname);
    if isempty(setdiff(reqfn, fn))
        ds = fname;
        clear('fname');
    else
        setdiff(reqfn, fn);
        error('Struct input does not have required fields');
    end
elseif mortar.legacy.isfileexist(fname)
    [dsfile, nds] = mortar.legacy.parse_filename(fname);
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
            ds(ii) = parse_gct_generic(dsfile{ii}, arg);
        end
    end
else
    error('mortar:parse_gct2:InvalidInput', 'InvalidInput')
end

end

% generic gct parser for versions (1.2, 1.3)
function ds = parse_gct_generic(fname, arg)
ds = struct('mat', [],...
    'rid', '',...
    'rhd', '',...
    'rdesc', '',...
    'cid', '',...
    'chd', '',...
    'cdesc', '',...
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
        error('Unknown version: %s', vrsn)
end

% col names
ds.cid = strtrim(x3{1}((2 + nrdesc):end));
checkid(ds.cid, arg.checkid);

nsamples = length(ds.cid);

% column descriptor row(s)
emptyval = {''};
ds.chd = cell(ncdesc, 1);
ds.cdesc = cell(nc, ncdesc);
for ii=1:ncdesc
    line = fgetl(fid);
    x = textscan(line, '%s', 'delimiter', '\t', 'bufsize', maxbuf);
    %sample desc
%     ds.coldesc(x{1}{1}) = x{1}((2+nrdesc):end);
    % empty value fix
    ds.chd{ii} = lower(x{1}{1});    
    ds.cdesc(:, ii) = [x{1}(2+nrdesc:end); emptyval(1:(nc+nrdesc+1 - length(x{1})))];
end
ds.cdict = mortar.legacy.list2dict(ds.chd);
% close file descriptor
fclose(fid);
% row name
ds.rid = cell(nr, 1);
if ~isempty(rowkeys)
    ds.rhd = rowkeys;
    % create dictionaries for row annotations
    ds.rdict = mortar.legacy.list2dict(ds.rhd);
    % row descriptors
    ds.rdesc = cell(nr, nrdesc);
end
switch(arg.class)
    case {'double','single'}
        ds.mat = zeros(nr, nc, arg.class);
        classfmt = '%f';
    case {'int8','uint8','int16','uint16','int32','uint32','int64','uint64'}
        ds.mat = zeros(nr, nc, arg.class);
        classfmt = '%d';
    case {'logical'}
        ds.mat = false(nr, nc);
        classfmt = '%d';
end

fmt = [repmat('%s', 1, 1+nrdesc), repmat(classfmt, 1, nsamples)];

mortar.legacy.dbg (arg.verbose, 'Reading %s [%dx%d]', fname, nr, nc);
mortar.legacy.dbg(arg.verbose, 'class:%s', arg.class);

%read line by line
if (arg.lowmem)
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
                'bufsize', maxbuf, 'headerlines', skip);
        else
            x = textscan(fid, fmt, maxline, 'delimiter', '\t', ...
                'bufsize', maxbuf);
        end
        
        if (lctr+maxline > lc)
            nrows = lc-lctr;
        else
            nrows = maxline;
        end
        % row name
        ds.rid(lctr+(1:nrows)) = strtrim(x{1});
        
        % row descriptor(s)
        for ii=1:nrdesc
            ds.rdesc(lctr+(1:nrows), ii) = x{1+ii};
        end
        ds.mat(lctr+(1:nrows),:) = [x{(2+nrdesc):end}];
        lctr = l*maxline;
        mortar.legacy.dbg(arg.verbose, 'read:%d/%d', min(lctr, lc), lc);
    end
end
checkid(ds.rid, arg.checkid);
mortar.legacy.dbg (arg.verbose, 'Done.\n');
fclose(fid);

if arg.detect_numeric
  if ncdesc    
    ds.cdesc = mortar.legacy.detect_numeric(ds.cdesc);                      
  end
  if nrdesc
    ds.rdesc = mortar.legacy.detect_numeric(ds.rdesc);                      
  end
end

end

function isok = checkid(id, error_flag)
% check if ids (cid,rid) are valid

dups = mortar.legacy.duplicates(id);
isok = true;
if ~isempty(dups)
    isok = false;
    disp(dups)
    if error_flag        
        error('Duplicate ids found')
    else
        warning('Duplicate ids found')
    end
end

end
