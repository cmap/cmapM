function saveMultiMatchedGutc(res, out_path, use_gctx)
% saveMultiMatchedGutc generate multi-resolution gutc dataset for
% multiple queries
% saveMultiMatchedGutc(RES, OUT_PATH)
if ~use_gctx
    gct_writer = @mkgct;
else
    gct_writer = @mkgctx;
end

if ~isdirexist(out_path)
    mkdir(out_path);
end

% pert
gct_writer(fullfile(out_path, 'pert_cell.gctx'), res.tpc, 'appenddim', false);    

% pert
gct_writer(fullfile(out_path, 'pert_id.gctx'), res.tp, 'appenddim', false);    

% pert
gct_writer(fullfile(out_path, 'pert_iname.gctx'), res.tn, 'appenddim', false);    

end
