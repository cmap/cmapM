function h = plot_gcdf(x, g, varargin)
% PLOT_GCDF Plot CDFs for grouped data
%   H = PLOT_GCDF(X, G)
config = struct('name', {'--location', '--labels', '--remove_nan'},...
    'default', {'southeast', '', false},...
    'help', {'Legend Location', 'Group Labels', 'Remove missing values (NaNs)'});
opt = struct('prog', mfilename, 'desc', 'Plot CDFs for grouped data');

[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

if ~help_flag
    x = x(:);
    g = g(:);
    assert(isequal(length(x), length(g)),...
        'X and Grouping variable must be the same length');
    if args.remove_nan
        not_nan = ~isnan(x);
        x = x(not_nan);
        gpidx_lut = mortar.containers.Dict(unique(g, 'stable'));
        g = g(not_nan);
        gpidx = gpidx_lut(unique(g, 'stable'));
    else 
        not_nan = [];
    end
    [cn, nl] = getcls(g);
    ng = length(cn);
    if ~isempty(args.labels)
        cn = args.labels;
        if isscalar(cn)
            cn = repmat(cn, ng, 1);
        elseif ~isempty(not_nan)
            cn = cn(gpidx);
        end
        assert(isequal(length(cn), ng),...
            'Length of group labels must match number of groups got %d expected %d',...
            length(cn), ng)
    end
    h = nan(ng, 1);
    for ii=1:ng
        this = nl == ii;
        this_x = x(this);
        h(ii) = cdfplot(this_x);
        hold on
    end
    legend(h, cn, 'location', args.location)
else
    disp('Help requested')
    h = [];
end
end