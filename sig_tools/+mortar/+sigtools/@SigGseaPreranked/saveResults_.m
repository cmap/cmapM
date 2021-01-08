function saveResults_(obj, out_path)

required_fields = {'args', 'query_result', 'nes_result', 'fdr_result'};
args = obj.getArgs;
res = obj.getResults; 
assert(has_required_fields(res, required_fields), 'Some required fields not found');

% Save results as matrices
dbg(1, 'Saving query result matrices');
saveMatrices(res, out_path);

% save digest folders
if args.save_digests
    dbg(1, 'Saving per-query digests');
    saveResultsPerQuery(res, out_path);
end
end

function matrix_out = saveMatrices(res, out_path)
%% save results as matrices
% cs.gctx: raw connectivity scores
% ncs.gctx: normalized score
% fdr_qvalue.gctx : FDR qvalues

matrix_out = fullfile(out_path, 'matrices');
mkdirnotexist(matrix_out)
mortar.compute.Connectivity.saveResult(res.query_result,...
    matrix_out, 'save_minimal', true, 'appenddim', false);
mkgctx(fullfile(matrix_out, 'nes.gctx'), res.nes_result, 'appenddim', false);
mkgctx(fullfile(matrix_out, 'fdr_qvalue.gctx'), res.fdr_result, 'appenddim', false);

end


function saveResultsPerQuery(res, out_path)
% save annotated GCT files for each query with ncs, cs and qvalues

% Build index table
index = gctmeta(res.nes_result, 'column');
index = mvfield(index, 'cid', 'query_id');
nquery = length(index);
url = cell(nquery, 1);

query_id = res.nes_result.cid;
    
% Save each query result in a subfolder
arf_path = fullfile(out_path, 'arfs');

for ii=1:nquery
    [~, sub_folder] = validate_path(upper(query_id{ii}), '_');
    this_out = fullfile(arf_path, sub_folder);
    mkdirnotexist(this_out);   
    url{ii} = path_relative_to(arf_path, this_out);
    this_ds = ds_slice(res.nes_result, 'cid', query_id(ii), 'checkid', false);
    this_ds.cid = {'norm_cs'};
    this_cs = ds_slice(res.query_result.cs, 'cid', query_id(ii), 'rid', this_ds.rid, 'checkid', false);
    this_ds = ds_add_meta(this_ds, 'row', 'raw_cs', num2cellstr(this_cs.mat, 'precision', 4));
    this_fdr = ds_slice(res.fdr_result, 'cid', query_id(ii), 'rid', this_ds.rid, 'checkid', false);    
    this_ds = ds_add_meta(this_ds, 'row', 'fdr_q_nlog10', num2cellstr(-log10(this_fdr.mat+eps), 'precision', 4));
    [~, srt_idx] = sort(this_ds.mat, 'descend');
    this_ds = ds_slice(this_ds, 'ridx', srt_idx);
    this_out_file = fullfile(this_out, 'gsea_result.gct');
    mkgctfast(this_out_file, this_ds, 'precision', 4, 'appenddim', false);
end

[index.url] = url{:};
% create the index file
mktbl(fullfile(arf_path, 'index.txt'), index)

end
