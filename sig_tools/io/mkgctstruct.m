function ds = mkgctstruct(mat, varargin)
% MKGCTSTRUCT Create a gct data structure.
% DS = MKGCTSTRUCT(mat, 'name1', 'value1', ...)
%   'mat': numeric data matrix
%   'rid': Row identifiers, cell array. Length must equal size(mat, 1).
%   'cid': Column identifiers, cell array. Length must equal size(mat, 2).
%   'rhd': Row header
%   'rdesc': Row descriptors
%   'chd': Column header
%   'cdesc': Column descriptors
%   'src': Source name

pnames = {'rid', 'cid',...
    'rhd', 'rdesc', 'chd',...
    'cdesc', 'src'};
dflts = {'', '', ...
    {}, {}, {},...
    {},'unnamed'};
args = parse_args(pnames, dflts, varargin{:});
if ~isvarexist('mat')
    mat = [];
end
[nr,nc]=size(mat);

assert(isequal(length(args.rid), nr),...
    'Length of rid must equal number of rows in mat');

assert(isequal(length(args.cid), nc),...
    'Length of cid must equal number of columns in mat');

if ~isempty(args.cdesc)
    nchd = length(args.chd);    
    if isvector(args.cdesc)
        if nchd>1
            % multiple fields -> row vector
            args.cdesc = args.cdesc(:)';
        else
            % single field -> column vector
            args.cdesc = args.cdesc(:);
        end
    end
    assert(isequal(size(args.cdesc, 1), nc),...
        'Length of cdesc must equal number of columns in mat');
    
    assert(isequal(size(args.cdesc, 2), length(args.chd)), ...
       'Length of chd must equal number of columns in cdesc');
elseif ~isempty(args.chd)
    args.cdesc = cell(nc, length(args.chd));
end

if ~isempty(args.rdesc)
    nrhd = length(args.rhd);
    if isvector(args.rdesc)
        if nrhd>1
            % multiple fields -> row vector
            args.rdesc = args.rdesc(:)';
        else
            % single field -> column vector
            args.rdesc = args.rdesc(:);
        end        
    end
    assert(isequal(size(args.rdesc, 1), nr),...
        'length of rdesc must equal number of rows in mat');    
    
    assert(isequal(size(args.rdesc, 2), length(args.rhd)),...
        'length of rhd must equal number of rows in rdesc');    
    
elseif ~isempty(args.rhd)
    args.rdesc = cell(nr, length(args.rhd));
end

if ~isempty(args.rhd)
    rdict = list2dict(args.rhd);    
else
    rdict = containers.Map();
end

if ~isempty(args.chd)
    cdict = list2dict(args.chd);    
else
    cdict = containers.Map();
end

ds = struct('mat', mat, ...
    'rid', {args.rid(:)},...
    'rhd', {args.rhd(:)},...
    'rdesc', {args.rdesc},...
    'cid', {args.cid(:)},...
    'chd', {args.chd(:)},...
    'cdesc', {args.cdesc},...
    'rdict', rdict,...
    'cdict', cdict,...
    'src', args.src,...
    'version', '#1.3');
    
end