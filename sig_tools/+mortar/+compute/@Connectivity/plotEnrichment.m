function hf = plotEnrichment(ds, gset, varargin)
% plotEnrichment Generate GSEA mountain plot
% HF = plotEnrichment(DS, GSET)
% inputs score matrix DS, geneset GS, filters
% generate ES plots for each geneset GS(i) with column in DS(:, j)

config = struct('name', {'--es_metric';'--show_fig';'--sample_field'},...
    'default', {'weighted'; true; '_id'},...
    'help', {'Enrichment statistic (weighted|classic). Default is weighted';
    'Display plot. default is true'; 'Metadata field to match set members. Default is _id'});
opt = struct('prog', mfilename, 'desc', 'Generate GSEA mountain plot');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

[nr, nc] = size(ds.mat);
sample_name = ds_get_meta(ds, 'column', args.sample_field);
% number of genesets
ng = length(gset);
esmat = nan(nc, ng);
set_size = zeros(length(gset), 1);
% rid_lut = list2dict(ds.rid);
rid_lut = mortar.containers.Dict(ds.rid);
hf = nan(nc*ng, 1);
for ic = 1:nc
    this_ds = ds_slice(ds, 'cidx', ic);
    this_sample_name = sample_name{ic};
for ii=1:ng
    tf = rid_lut.iskey(gset(ii).entry);    
    if nnz(tf)>0
        ridx = rid_lut(gset(ii).entry(tf));
        set_size(ii) = length(ridx);
        switch lower(args.es_metric)
            case 'weighted'
                [res, hitrank, hitind, esmax] = compute_es(ridx, this_ds.mat, [], 'weight', 'weighted', 'isranked', false);
            case 'classic'
                rnk = rankorder(this_ds.mat, 'direc', 'descend',...
                    'zeroindex','false', 'fixties', false);
                [res, hitrank, hitind, esmax] = compute_es(ridx, rnk, [], 'weight', 'weighted', 'isranked', true);
        end
        esmat(:, ii) = esmax;
        title_str = sprintf('%s [%d] v %s', gset(ii).head, length(hitrank), this_sample_name);
        hf(ic*ii) = plot_es(res, hitrank, args.show_fig, title_str);
    else
       warning('%s vs %s No mappable features in cell set, skipping', gset(ii).head, this_sample_name)
    end
end
end


end

function hf = plot_es(res, hitrank, show_fig, title_str)

N = length(res);
hf = myfigure(show_fig);
line_color = get_color('forest');
max_color = get_color('orange');
raster_color = get_color('scarlet');
plot(1:N, res, 'color', line_color, 'linewidth', 2 );
hold on
plot_constant(0, 'color', 'b', 'linestyle', ':', 'show_label', false);
xlim([1 N])
hr = rasterplot(hitrank, 1, N, gca);
set(hr, 'color', raster_color, 'linewidth', 2)
ylim([-1 1]);
xlabel ('Rank in Ordered Dataset');
ylabel ('Enrichment Score (ES)');
[absmax, maxidx] = max(abs(res));
es_max = absmax.*sign(res(maxidx));
plot(maxidx, es_max, 'o', 'markerfacecolor', max_color);
text(maxidx + 0.05, es_max + sign(es_max)*0.1, sprintf('%2.3f', es_max),...
    'color', 'b', 'fontsize', 14, 'fontweight', 'bold');
title(texify(title_str));
namefig(title_str)

end