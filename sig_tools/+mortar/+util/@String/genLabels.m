function lbl = genLabels(varargin)
% GEN_LABEL Generate labels
s = struct('name',...
    {'n'; '--zeropad'; '--prefix'; '--suffix'},...
    'default',...
    {[]; true; ''; ''});
p = mortar.common.ArgParse('gen_label');
p.add(s);

args = p.parse(varargin{:});
if length(args.n)>1
    seq = args.n;
else
    if args.n>0
        seq = 1:args.n;
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

lbl = cell(length(seq), 1);
for ii=1:length(seq)
    lbl{ii, 1} = sprintf(fmt, seq(ii));
end
end
