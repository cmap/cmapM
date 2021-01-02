function gmt = tbl2gmt_multi(tbl, varargin)
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

pnames = {'group_field', 'member_field',...
          'group_prefix'};
dflts = {'group_id', 'member_id',...
         ''};
args = parse_args(pnames, dflts, varargin{:});

if isfileexist(tbl)
    tbl = parse_tbl(tbl, 'outfmt', 'record');
elseif ~isstruct(tbl)
    error('File not found');
end

if ischar(args.group_field)
    group_field = {args.group_field}';
else
    group_field = args.group_field;
end
assert(all(isfield(tbl, group_field)), 'Missing some group fields');
ngp = length(group_field);
sets_list = cell(ngp, 1);
for ii=1:ngp
    if ~isempty(args.group_prefix)
        group_prefix = sprintf('%s_%s',  args.group_prefix, group_field{ii});
    else
        group_prefix = group_field{ii};
    end
    
    sets_list{ii} = tbl2gmt(tbl,...
                            'group_field', group_field{ii},...
                            'member_field', args.member_field,...
                            'desc_field', group_field{ii},...
                            'group_prefix', group_prefix);                                
end

gmt = cat(1, sets_list{:});

end