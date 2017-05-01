function lbls = gen_labels(n, varargin)
% GEN_LABELS Generate labels
% LBLS = GEN_LABELS(N, PREFIX, SUFFIX)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

pnames = {'-prefix','-suffix','-zeropad'};
dflts = {'', '', true};
args = parse_args(pnames, dflts, varargin{:});

if length(n)>1
    seq=n;
else
    if n>0
        seq=1:n;
    else
        error ('N should be > 0');
    end
end

if args.zeropad
    maxdigits = floor(log10(max(seq)))+1;
    fmt = sprintf('%s%%.%dd%s', args.prefix, maxdigits, args.suffix);
else
    fmt = sprintf('%s%%d%s', args.prefix, args.suffix);
end

lbls = cell(length(seq), 1);
for ii=1:length(seq)
    lbls{ii,1} = sprintf(fmt, seq(ii));
end

