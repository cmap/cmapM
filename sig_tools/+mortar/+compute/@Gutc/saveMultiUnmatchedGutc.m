function saveMultiUnmatchedGutc(res, out_path, use_gctx)
% SAVEMULTIUNMATCHEDGUTC generate multi-resolution gutc dataset for
% multiple queries
% SAVEMULTIUNMATCHEDGUTC(RES, OUT_PATH)
if ~use_gctx
    gct_writer = @mkgct;
else
    gct_writer = @mkgctx;
end

if ~isdirexist(out_path)
    mkdir(out_path);
end

% Query info
mktbl(fullfile(out_path, 'query_info.txt'), res.query_info);

% sig level
cs = ds_slice(res.cs_sig, 'rid', res.ns_sig.rid);
% raw score
gct_writer(fullfile(out_path, 'cs_sig.gctx'),...
    cs, 'appenddim', false);

% norm score
gct_writer(fullfile(out_path, 'ns_sig.gctx'),...
    res.ns_sig, 'appenddim', false);
% ps / tau values
if ~isempty(res.ps_sig)
    gct_writer(fullfile(out_path, 'ps_sig.gctx'),...
        res.ps_sig, 'appenddim', false);
end

% pert_cell
if ~isempty(res.ns_pert_cell)
    gct_writer(fullfile(out_path, 'ns_pert_cell.gctx'),...
        res.ns_pert_cell, 'appenddim', false);
end
if ~isempty(res.ps_pert_cell)
    gct_writer(fullfile(out_path, 'ps_pert_cell.gctx'),...
        res.ps_pert_cell, 'appenddim', false);
end
% pert_summary
if ~isempty(res.ns_pert_summary)
    gct_writer(fullfile(out_path, 'ns_pert_summary.gctx'),...
        res.ns_pert_summary, 'appenddim', false);
end
if ~isempty(res.ps_pert_summary)
    gct_writer(fullfile(out_path, 'ps_pert_summary.gctx'),...
        res.ps_pert_summary, 'appenddim', false);
end
% pcl_cell
if ~isempty(res.ns_pcl_cell)
    gct_writer(fullfile(out_path, 'ns_pcl_cell.gctx'),...
        res.ns_pcl_cell, 'appenddim', false);
end
if ~isempty(res.ps_pcl_cell)
    gct_writer(fullfile(out_path, 'ps_pcl_cell.gctx'),...
        res.ps_pcl_cell, 'appenddim', false);
end
% pcl_summary
if ~isempty(res.ns_pcl_summary)
    gct_writer(fullfile(out_path, 'ns_pcl_summary.gctx'),...
        res.ns_pcl_summary, 'appenddim', false);
end
if ~isempty(res.ps_pcl_summary)
    gct_writer(fullfile(out_path, 'ps_pcl_summary.gctx'),...
        res.ps_pcl_summary, 'appenddim', false);
end
end