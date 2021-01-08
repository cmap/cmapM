function makeEnrichmentPlots(ds, gset)
% inputs score matrix DS, geneset GS, filters
% generate ES plots for each geneset GS(i) with column in DS(:, j)

es_metric = 'weighted';
show_fig = true;
[nr, nc] = size(ds.mat);
% number of genesets
ng = length(gset);
esmat = nan(nc, ng);
set_size = zeros(length(gset), 1);
% rid_lut = list2dict(ds.rid);
rid_lut = mortar.containers.Dict(ds.rid);
hf = nan(nc*ng, 1);
for ic = 1:nc
    this_ds = ds_slice(ds, 'cidx', ic);
for ii=1:ng
    tf = rid_lut.iskey(gset(ii).entry);
    %     ridx = cell2mat(rid_lut.values(gset(ii).entry));
    if nnz(tf)>0
        ridx = rid_lut(gset(ii).entry(tf));
        set_size(ii) = length(ridx);
        switch lower(es_metric)
            case 'weighted'
                [res, hitrank, hitind, esmax] = compute_es(ridx, ds.mat, [], 'weight', 'weighted', 'isranked', false);
            case 'classic'
                rnk = rankorder(ds.mat, 'direc', 'descend',...
                    'zeroindex','false', 'fixties', false);
                [res, hitrank, hitind, esmax] = compute_es(ridx, rnk, [], 'weight', 'weighted', 'isranked', true);
        end
        esmat(:, ii) = esmax;
        title_str = sprintf('%s v %s', gset(ii).head, this_ds.cid);
        hf(ic*ii) = plotEnrichment(res, hitrank, show_fig, title_str);
    end
end
end


end

function hf = plotEnrichment(res, hitrank, show_fig, title_str)

N = length(res);
hf = myfigure(show_fig);
plot(1:N, res, 'g', 'linewidth', 2 );
hold on
plot_constant(0);
xlim([1 N])
rasterplot(hitrank, 1, N, gca);
ylim([-1 1]);
xlabel ('Rank in Ordered Dataset');
ylabel ('Enrichment Score (ES)');
[absmax, maxidx] = max(abs(res));
es_max = absmax.*sign(res(maxidx));
plot(maxidx, es_max, 'ro');
text(maxidx+randn(1)*0.01, es_max+randn(1)*0.01, sprintf('ESMAX: %2.3f', es_max), 'fontsize', 7);
title(texify(title_str));
namefig(title_str)

end