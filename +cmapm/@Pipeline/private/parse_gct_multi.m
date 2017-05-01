function ds = parse_gct_multi(fn, varargin)
pnames = {'version'};
dflts = {'2'};
arg = parse_args(pnames, dflts, varargin{:});

dsfile = parse_filename(fn, 'wc', '*.gct');
nds = length(dsfile);

for ii=1:nds
    fprintf('%d/%d\n', ii, nds);
    switch arg.version
        case '2'
            ds(ii) = parse_gct(dsfile{ii}, varargin{:});
        otherwise
            error('Invalid version')
    end
end
