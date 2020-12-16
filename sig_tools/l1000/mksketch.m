function sketch = mksketch(m, varargin)
pnames = {'usemedian'};
dflts = {false};
args = parse_args(pnames, dflts, varargin{:});

if args.usemedian
    middle = 'median';
    middlefn = @median;
else
    middle = 'mean';
    middlefn = @mean;
end

%% sort matrix
[nr, nc] = size(m);
srt = sort(m);
x = middlefn(srt, 2);
cid = sprintf('sketch_%s_%d', middle, nc);
rid = gen_labels(nr,'zeropad', false);
sketch = mkgctstruct(x,'rid',rid, 'cid', {cid});

end