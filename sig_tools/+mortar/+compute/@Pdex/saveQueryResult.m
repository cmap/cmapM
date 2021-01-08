function saveQueryResult(res, out_path, use_gctx)
% saveQueryResult Save PDEX query results
% saveQueryResult(res, out_path, use_gctx)

if ~use_gctx
    gct_writer = @mkgct;
else
    gct_writer = @mkgctx;
end

if ~isdirexist(out_path)
    mkdir(out_path);
end

% query stats
mktbl(fullfile(out_path, 'query_stats.txt'), res.query_stats);

% Raw CS
gct_writer(fullfile(out_path, 'cs.gctx'),...
    res.cs, 'appenddim', false);

% normalized CS
gct_writer(fullfile(out_path, 'ns.gctx'),...
     res.ns, 'appenddim', false);

% percentiles
gct_writer(fullfile(out_path, 'ps.gctx'),...
    res.ps, 'appenddim', false);

end
