function build_ranks(zs)
% Compute rank matrices for a given z-score file

zs = parse_gctx(zs);
wkdir = mktoolfolder(pwd, mfilename);

%% compute ranks
rank_full = score2rank(zs);
rank_bing = score2rank(gctextract_tool(zs, 'rid', '/cmap/data/vdb/spaces/bing_n10638.grp'));
rank_lm = score2rank(gctextract_tool(zs, 'rid', '/cmap/data/vdb/spaces/lm_epsilon_n978.grp'));

%%
mkgctx(fullfile(wkdir, 'rank_full.gctx'), rank_full);
mkgctx(fullfile(wkdir, 'rank_bing.gctx'), rank_bing);
mkgctx(fullfile(wkdir, 'rank_lm.gctx'), rank_lm);

end