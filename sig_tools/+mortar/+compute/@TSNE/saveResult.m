function saveResult(res, wkdir)
% Save reports
    if ~mortar.common.FileUtil.isfile(wkdir, 'dir')
        mkdir(wkdir)
    end
    
    print_args('runTsne', fullfile(wkdir, 'tsne_params.txt'), res.args);

    % Tsne result matrix
    mkgctx(fullfile(wkdir, 'tsne.gctx'), res.ds);
    
    rpt = struct('cost', res.cost);
    mktbl(fullfile(wkdir, 'stats.txt'), rpt)
    
end
