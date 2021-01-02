function [rpt, ps_lm, ps_bing, ps_full] = genesym2probeset(gs)
% Map gene symbold to probesets
% [RPT, PS_LM, PS_BING, PS_FULL] = GENESYM2PROBESET(GS)

gs = parse_geneset(gs);
ngs = length(gs);
all_gene = setunion(gs);
ginfo = gene_info(all_gene, 'query_field', 'pr_gene_symbol',...
                  'fields', {'pr_id', 'pr_gene_symbol', 'is_lm', 'is_bing', 'pr_pool_id'});

ismissing = cellfun(@isempty, {ginfo.pr_id});
mapped = ginfo(~ismissing);
dbg(1, '%d/%d genes mapped to probes', length(all_gene), nnz(~ismissing))
pr_id = {mapped.pr_id}';
gene_sym = {mapped.pr_gene_symbol}';

% only consider epsilon probes
is_lm = cellfun(@(x) any(strcmp(x, 'epsilon')), {mapped.pr_pool_id}');
%is_lm = [mapped.is_lm]';
is_lm_idx = find(is_lm);

is_bing = [mapped.is_bing]';
is_bing_idx = find(is_bing);

% mapping report
% gsid, mapped, missing, num_lm, num_bing, num_full
rpt = struct('gset_id', {gs.head}', ...
             'gset_size', {gs.len}', ...
             'num_gene_mapped', 0,...
             'num_gene_missing', 0,...
             'num_probe_lm', 0,...
             'num_probe_bing', 0,...
             'num_probe_full', 0);

ps_lm = gs;
ps_bing = gs;
ps_full = gs;

for ii=1:ngs
% landmarks
[clm, ~, ilm] = map_ord(gs(ii).entry, gene_sym(is_lm));
ps_lm(ii).entry = pr_id(is_lm_idx(ilm));
ps_lm(ii).len = length(clm);

% bing
[cbing, ~, ibing] = map_ord(gs(ii).entry, gene_sym(is_bing));
ps_bing(ii).entry = pr_id(is_bing_idx(ibing));
ps_bing(ii).len = length(cbing);

% full
[cfull, igs, ifull] = map_ord(gs(ii).entry, gene_sym);
ps_full(ii).entry = pr_id(ifull);
ps_full(ii).len = length(cfull);

num_gene_mapped = length(unique(igs));
rpt(ii).num_gene_mapped = num_gene_mapped;
rpt(ii).num_gene_missing = rpt(ii).gset_size - num_gene_mapped;
rpt(ii).num_probe_lm = length(clm);
rpt(ii).num_probe_bing = length(cbing);
rpt(ii).num_probe_full = length(cfull);

end