function es_plot(es, hitrank, hitind)
N = length(es);
subplot(2,1,1)
plot(hitind, es(hitind),'g.','linewidth', 2);
hold on
plot([1 N],[0 0],'k');
xlim([1 N])
%yl = ylim;
subplot(2,1,2)
rasterplot(hitrank, 1, N, gca);
ylim([-1 1]);
xlabel ('Gene List Rank');
ylabel ('Running Enrichment Score');
% s=texify(sprintf('Geneset:%s Instance:%s (Down Regulated)',dn_gsname{gsind},sid{instind}));
% title(s);