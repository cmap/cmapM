function mksdf(sdffile, ds, varargin)
pnames = {'keep_desc', 'keep_sample', 'sort_order'};
dflts = {'', [], ''};
args = parse_args(pnames, dflts, varargin{:});

%fields to keep
if ~isempty(args.keep_desc)
    fn = intersect_ord(ds.chd.keys, args.keep_desc);
else
    fn = ds.chd;
%     fn = ds.chd.keys;
end
% fnidx = cell2mat(ds.chd.values(fn));
fnidx = cell2mat(ds.cdict.values(fn));

% samples to keep
if isempty(args.keep_sample)
    sidx = 1:length(ds.cid);
else
    sidx = args.keep_sample;
end
%sort order of records
if ~isempty(args.sort_order)
    sort_index = cell2mat(ds.cdict.values(args.sort_order));
    [~, srtidx] = sorton(ds.cdesc(sidx, sort_index), 1:length(args.sort_order));
    sidx = sidx(srtidx);
end

fid = fopen(sdffile, 'wt');
print_dlm_line2([{'SAMPLE_NAME'}; fn], 'fid', fid)
for ii=1:length(sidx)
    print_dlm_line2([ds.cid(sidx(ii)),  ...
        ds.cdesc(sidx(ii), fnidx)], ...
        'fid', fid, 'precision',2)
end
fclose(fid);
