function gctx2gct(p, varargin)
% Convert gctx to gct format

[fn, fp] = find_file(p);
isgctx = ~cellfun(@isempty, regexp(fn,'.gctx$'));
fp = fp(isgctx);
fn = fn(isgctx);
nds = length(fp);
for ii=1:nds
    dbg (1, '%d / %d %s', ii, nds, fn{ii});
    ds = parse_gctx(fp{ii}); 
    mkgct(ds.src, ds); 
end

end