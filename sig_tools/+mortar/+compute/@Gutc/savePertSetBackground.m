function savePertSetBackground(bkg, outpath)
% savePertSetBackground Save output from genPertSetBackground
% savePertSetBackground(bkg, outpath)

req_fn = {'ns','ns2ps', 'stats'};
[tf, missing] = check_struct_field(bkg, req_fn, 'error');
if ~isdirexist(outpath)
    mkdir(outpath)
end

mkgctx(fullfile(outpath, 'ns.gctx'), bkg.ns, 'appenddim', false);
mkgctx(fullfile(outpath, 'ns2ps.gctx'), bkg.ns2ps, 'appenddim', false);
mkgctx(fullfile(outpath, 'stats.gctx'), bkg.stats, 'appenddim', false);

end