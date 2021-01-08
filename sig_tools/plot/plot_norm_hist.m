function h = plot_norm_hist(varargin)
% PLOT_NORM_HIST Plot normalized histograms.
%   PLOT_NORM_HIST(X) bins the elements in X into 10 equally spaced
%   containers.
%   PLOT_NORM_HIST(X, NBIN) uses NBINS number of bins where NBINS is a scalar.
%   PLOT_NORM_HIST(X, C) where C is a vector returns the distribution of X
%   among length(C) bins with centers specified by C.
%   PLOT_NORM_HIST(X, NBIN, 'param', value)
%       'type': String, Type of normalization to use. Options are:
%
%               'relfreq': Relative frequency histogram (default). The
%               height of a bar in a relative frequency histogram is the
%               fraction of samples that fell within that bar's interval.
%               The sum of all the bar-heights is one.
%                
%               'relpct': same as 'relfreq' except frequencies are
%               expressed as a percentage of total samples. The bars sum to
%               100.
%
%               'pdf': Probability density histogram. The height of the bar
%               in a probability density histogram gives the probability
%               per unit length of the x-axis. Multiplying a bar's height
%               by its width gives the fraction of samples that fall into
%               the bin. The sum of the area of all the bars is one.
%
%               'freq': Absolute frequency (count). Same as hist.
%
%       'style' : String, Plot style
%               'bar' : default
%               'step' : an unfilled line plot.
%
% See also hist.

pnames = {'type', 'style'};
dflts = {'relfreq', 'bar'};

% Parse possible Axes input
[cax,args,nargs] = axescheck(varargin{:});

y = args{1};
% find first string argument
[reg, pvpairs] = parseparams(args);

% extract local parameters
[local_args, ext_args] = get_local_params(pvpairs, pnames);
args = parse_args(pnames, dflts, local_args{:});

% compute histogram
[n, bc] = hist(reg{:}, ext_args{:});

switch(lower(args.type))
    case 'relfreq'
        % relative frequency histogram
        n = n/sum(n);
    case 'relpct'
        % relative frequency histogram expressed as a percentage
        n = 100*n/sum(n);
    case 'pdf'
        % probability density
        n = n/(sum(n)*(bc(2)-bc(1)));
    case 'freq'
        % absolute frequency / count
        % n = n;
    otherwise
        error('Unknown type:%s', args.type)
end

switch(lower(args.style))
    case 'bar'
        h = bar(bc, n, 'histc');
    case 'step'    
        h = stairs(bc, n);
    otherwise
        error('Unknown style: %s', args.style);
end


end