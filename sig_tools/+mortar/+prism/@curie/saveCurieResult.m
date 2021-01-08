function saveCurieResult(res, outpath, use_gctx, skip_key_as_text)
% saveCurieResult Save results produced by runCurie
% saveCurieResult(res, outpath, use_gctx)

if ~mortar.util.File.isfile(outpath, 'dir')
    mkdir(outpath)
end

if use_gctx
    gctwriter=@mkgctx;
else
    gctwriter=@mkgct;
end

% save arguments
% print_args('query_tool', fullfile(outpath, 'query_tool_params.txt'), res.args);

% save genesets
mkgmt(fullfile(outpath, 'up.gmt'), res.uptag);
mkgmt(fullfile(outpath, 'dn.gmt'), res.dntag);

if ~isempty(res.unmapped_up)
    mkgmt(fullfile(outpath, 'unmapped_queries_up.gmt'), res.unmapped_up);
end
if ~isempty(res.unmapped_down)
    mkgmt(fullfile(outpath, 'unmapped_queries_down.gmt'), res.unmapped_down);
end

% save result matrices
result_fields = {'pctrank_row', 'pctrank_col', 'ncs', 'cs', 'cs_up', 'cs_dn', 'leadf_up', 'leadf_dn'};
% matrices to output at GCT (ignoring of the use_gctx flag)
gct_fields = {'ncs'};

for ii=1:length(result_fields)
    if isfield(res, result_fields{ii}) && isds(res.(result_fields{ii}))
        outfile = fullfile(outpath, sprintf('%s.gctx', result_fields{ii}));
        gctwriter(outfile, res.(result_fields{ii}), 'appenddim', false);
        if use_gctx && ~skip_key_as_text && ismember(result_fields{ii}, gct_fields)
            dbg(1, 'Saving %s matrix as text', result_fields{ii})
            mkgct(outfile, res.(result_fields{ii}), 'appenddim', false);
        end
    end
end

end