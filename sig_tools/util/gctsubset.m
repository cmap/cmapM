function ds0 = gctsubset(ds, varargin)

% ds0 = gctsubset(ds, varargin) - grab a subset of rows or columns from a
% gct struct
%   Arguments:
%   - csubset: a vector of integers from 1:numel(ds.cid); ds0 will contain
%       only those columns.  Applies to all column fields, e.g. cdesc.
%   - rsubset: a vector of integers from 1:numel(ds.rid); ds0 will contain
%       only those rows.  Applies to all row fields, e.g. rdesc.

% Not currently implemented:
%   - savefile: Save struct to gct file.  Default is 0.
%   - outdir: path to folder to which to save the struct
%   - dsname: filename

pnames = {'csubset', ...
    'rsubset', ...
    'savefile', ...
    'outdir', ...
    'dsname'
    };

dflts = {[], ...
    [], ...
    0, ...
    '.', ...
    ''
    };

args = parse_args(pnames, dflts, varargin{:});

ds0 = ds;

if ~isempty(args.csubset)
    ds0.mat = ds0.mat(:, args.csubset);
    ds0.cid = ds0.cid(args.csubset);
    ds0.cdesc = notempty(ds0.cdesc, args.csubset);
end

if ~isempty(args.rsubset)
    ds0.mat = ds0.mat(args.rsubset, :);
    ds0.rid = ds0.rid(args.rsubset);
    ds0.rdesc = notempty(ds0.rdesc, args.rsubset);
end

end


function ret = notempty(vector, subset)
    ret = vector;
    if ~isempty(vector)
        ret = vector(subset, :);
    end
end