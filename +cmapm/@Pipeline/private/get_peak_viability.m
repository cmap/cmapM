function [nviable, nviable_cnt, nviable_pct] = get_peak_viability(pkstats, min_support, min_support_pct)
[nr, nc] = size(pkstats);
nviable_cnt = reshape(cellfun(@(x) nnz(x>=min_support), {pkstats.pksupport}),nr,nc);
nviable_pct = reshape(cellfun(@(x) nnz(x>=min_support_pct), {pkstats.pksupport_pct}), nr, nc);
nviable = min(nviable_cnt, nviable_pct);
end
