function makeResultStruct(res_folder)
% makeResultsStruct generate results structure from queryl1k tool matrices
% output
cs_file = fullfile(res_folder, 'cs.gctx');
ncs_file = fullfile(res_folder, 'ncs.gctx');
fdr_file = fullfile(res_folder, 'fdr_qvalue.gctx');

cs = parse_gctx(cs_file);
ncs_result = parse_gctx(ncs_file);
fdr_result = parse_gctx(fdr_file);

query_result = struct('cs', cs);

res = struct('args', [],...
    'query_result', query_result,...
    'ncs_result', ncs_result,...
    'ncs_rpt', [],...
    'fdr_result', fdr_result);

end