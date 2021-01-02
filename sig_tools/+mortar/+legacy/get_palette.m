function nrgb = get_palette(n, varargin)
pnames = {'scheme_file', 'scheme'};
dflts = {'/cmap/data/vdb/color/color_schemes.gmt',...
    'distinct10'};
args = parse_args(pnames, dflts, varargin{:});
builtin_map = list2dict({'jet','hsv',...
    'hot','cool','spring',...
    'summer','autumn','winter',...
    'gray','bone','copper',...
    'pink'});
if builtin_map.isKey(args.scheme)
    if nargin<1 || isempty(n)
        nrgb = feval(args.scheme, n);
    else
        nrgb = feval(args.scheme, n);
    end
else
    
    all_schemes = parse_gmt(args.scheme_file);
    pick = all_schemes(strcmp(args.scheme, {all_schemes.head}));
    if nargin < 1 || isempty(n)
        n = pick.len;
    end
    
    if n > pick.len
        nrgb = get_color(pick.entry(mod(0:n-1, pick.len)+1));
    else
        nrgb = get_color(pick.entry(1:n));
    end
    
end