function [sidx, isbad, metric] = bad_samples(qcstat, varargin)
% BAD_SAMPLES Flag outlier samples in the data.
pnames = {'metric', ...
    'minval', 'tail'};
dflts = {{'calib_slope_deg', 'f_logpval', 'iqr'},...
    [45, 4, 5], {'left', 'left', 'both'}};
arg = parse_args(pnames, dflts, varargin{:});
nfn=length(arg.metric);
isbad = zeros(length(qcstat.sample), nfn);
for ii=1:nfn
    x = qcstat.(arg.metric{ii});
    lowidx = find(x < arg.minval(ii));
    o = union( lowidx, outlier1d(x, 'cutoff', 2, 'tail', arg.tail{ii}));    
    isbad(o, ii) = 1;
end
sumbad = sum(isbad, 2);
numstrikes = length(arg.metric)/2;
%if qcpass field does not exist (e.g. in GEX)
if ~isfield(qcstat, 'qcpass')
    sidx = find(sumbad > numstrikes);
else
    sidx = find(sumbad > numstrikes | ~qcstat.qcpass);
end

metric = arg.metric;
end