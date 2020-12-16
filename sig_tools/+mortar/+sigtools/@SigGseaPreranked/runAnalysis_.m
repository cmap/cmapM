function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)
% Main function

%% Run Cmap Query
dbg(args.verbose, '# Running Set enrichment');
score_ds = parse_gctx(args.score);
rank_ds = parse_gctx(args.rank);

query_result = mortar.compute.Connectivity.runCmapQuery(...
    'score', score_ds, ...
    'rank', rank_ds, ...
    'uptag', args.up,...
    'es_tail', args.es_tail,...
    'metric', args.metric,...
    'sig_meta', args.sig_meta,...
    'query_meta', args.query_meta,...
    'max_col', args.max_col);

% transpose the cs file to [sets x num_cols_in_score]
query_result.cs = transpose_gct(query_result.cs);
set_sizes = [query_result.uptag.len]';

dbg(args.verbose, '# Normalizing scores and computing null distributions');
[nes_result, fdr_result] = mortar.compute.Gutc.normalizeQueryWithPermutedNull(...
        query_result.cs, score_ds, rank_ds, set_sizes, 'num_perm', args.num_perm);

res = struct('args', args,...
    'query_result', query_result,...
    'nes_result', nes_result,...
    'fdr_result', fdr_result);

end
