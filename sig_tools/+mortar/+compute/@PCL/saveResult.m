function saveResult(res, wkdir)
% Save reports
% saveResult(res, wkdir)

    if ~mortar.common.FileUtil.isfile(wkdir, 'dir')
        mkdir(wkdir)
    end
    
    print_args('runPCLAnalysis', fullfile(wkdir, 'pcl_params.txt'), res.args);

    % scores in the PCL space
    mkgctx(fullfile(wkdir, 'pclmember_score'), res.ds);
    % PCL's used
    mkgmt(fullfile(wkdir, 'pcl.gmt'), res.pcl);
    % PCL info
    mktbl(fullfile(wkdir, 'pcl_info.txt'), res.pcl_info);
    % PCL metrics
    metric = {'median', 'iqr', 'maxq'};
    % annotations to keep
    keep_fields = {'pert_id', 'pert_iname', 'cell_id',...
                   'pert_type', 'pert_idose', 'pert_itime',...
                   'distil_ss', 'distil_cc_q75', 'ts_cell_id'};

    [rhd,~,idx]=intersect(keep_fields, res.rpt.rhd, 'stable');
    rdesc = res.rpt.rdesc(:, idx);
    for ii=1:length(metric)
        this_ds = mkgctstruct(res.rpt.(metric{ii}),...
                              'rid', res.rpt.rid,...
                              'cid', res.rpt.cid,...
                              'rhd', rhd,...
                              'rdesc', rdesc,...
                              'chd', res.rpt.chd,...
                              'cdesc', res.rpt.cdesc);
        mkgctx(fullfile(wkdir, sprintf('pcl_%s.gctx', metric{ii})), this_ds);        
        if isequal(metric{ii}, 'median')
            % for the PCL app
            mkgct(fullfile(wkdir, sprintf('pcl_%s.gct', metric{ii})), this_ds);
        end
    end
    
end
