function [g, tbl] = ds2set(varargin)
% DS2SET Convert matrix to feature set
%

[args, help_flag] = getArgs(varargin{:});
if ~help_flag
    
    group_id = ds_get_meta(args.ds, 'column', args.group_field);
    desc = ds_get_meta(args.ds, 'column', args.desc_field);
    member_id = ds_get_meta(args.ds, 'row', args.member_field);
    
    if ~isempty(args.is_member)
        tf = args.is_member>0;
    else
        tf = ~isnan(args.ds.mat) & args.ds.mat > 0;
    end
    [ir, ic] = find(tf);
    tbl = struct('group_id', group_id(ic),...
        'desc', desc(ic),...
        'member_id', member_id(ir));
    g = tbl2gmt(tbl);
end
end

function [args, help_flag] = getArgs(varargin)

pnames = {'ds';...
    '--group_field';...
    '--desc_field';...
    '--member_field';...
    '--is_member'};

defaults = {'';...
    '_id';...
    '_id';...
    '_id';...
    []};

help_str = {'GCT(x), Matrix of features x samples, non-nan and values > zero are considered set members';...
    'Set grouping field, must match column metadata field';...
    'Set description field, must be a column metadata field';...
    'Set member field, must be a row metadata field';...
    'Logical matrix with same dimensions of ds, set members are selected if is_member>0'};

config = struct('name', pnames,...
    'default', defaults,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', '');

[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

% Validate inputs
assert(isds(args.ds) || all(isfileexist(args.ds)),...
    'Required argument ds missing');
args.ds = parse_gctx(args.ds);

if ~isempty(args.is_member)
    assert(isequal(size(args.is_member), size(args.ds.mat)), 'dimensions of is_member should match ds')
end

end