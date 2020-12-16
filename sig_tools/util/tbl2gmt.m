function gmt = tbl2gmt(tbl, varargin)
% TBL2GMT Convert a table to sets.
%   G = TBL2GMT(T) generates sets from a table T based on values specified
%   in the grouping field called 'group_id'. G is a geneset structure
%   similar to that returned by the parse_gmt function.
%
%   G = TBL2GMT(T, param1, value1,...) Specify optional parameters. The
%   following parameters are supported:
%
%   'group_field' : field to use for grouping. Default is 'group_id'
%   'desc_field' : field to use as the description of the set. Default is
%                   'desc'
%   'member_field' : field to use as the set member. Default is 'member_id'
%
%   See also parse_gmt

pnames = {'group_field', 'desc_field', 'member_field',...
          'group_prefix', 'group_suffix'};
dflts = {'group_id', 'desc', 'member_id',...
         '', ''};
args = parse_args(pnames, dflts, varargin{:});

if isfileexist(tbl)
    tbl = parse_tbl(tbl, 'outfmt', 'record');
elseif ~isstruct(tbl)
    error('File not found');
end

assert(all(isfield(tbl, {args.group_field, args.desc_field, args.member_field})),...
    'Missing fields');

if ~isempty(tbl)
    [hd, nl] = getcls({tbl.(args.group_field)});
    if ~isempty(args.group_prefix)
        hd = strcat(args.group_prefix, '_', hd);
    end
    
    if ~isempty(args.group_suffix)
        hd = strcat(hd, '_', args.group_suffix);
    end
    
    ng = length(hd);
    gmt = struct('head', hd, 'desc', '', 'entry', '', 'len', '');
    
    for ii=1:ng
        keep = nl == ii;
        gmt(ii).desc = print_dlm_line(unique({tbl(keep).(args.desc_field)}, 'stable'), 'dlm', '|');
        entry = {tbl(keep).(args.member_field)}';
        entry = entry(~cellfun(@isempty, entry));
        gmt(ii).entry = unique(entry, 'stable');
        gmt(ii).len = numel(gmt(ii).entry);
    end
    % exclude empty sets
    gmt = gmt([gmt.len]'>0);
else
    gmt = struct([]);
end

end