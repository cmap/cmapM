function [hf, ov] = plot_set_overlap(a, b, metric)
% plot heatmap of overlap between two sets
% assumes sets of same size ordered in the same way
a = parse_geneset(a);
b = parse_geneset(b);

na = length(a);
nb = length(b);
assert(isequal(na, nb), 'set sizes dont match');
ov = setoverlap(a, b, metric);
% pairwise B x A matrix
ov = ds_slice(ov, 'cidx', 1:na, 'ridx', na+(1:na));
[~, ord] = sort(diag(ov.mat), 'descend');
ov = ds_slice(ov, 'cidx', ord, 'ridx', ord);

hf = figure;
imagesc(ov.mat);
caxis([0 1]);
axis square
colorbar
colormap(flipud(gray(7)));
grid off

xsz = num2cellstr(ds_get_meta(ov, 'column', 'set_size'));
ysz = num2cellstr(ds_get_meta(ov, 'row', 'set_size'));

xlbl = regexprep(ov.cid, 'BRD-[A-Z0-9]{5}','');
xlbl = strcat(xlbl, ' (', xsz, ')');

ylbl = regexprep(ov.rid, 'BRD-[A-Z0-9]{5}','');
ylbl = strcat(ylbl, ' (', ysz, ')');

set(gca, 'xtick', 1:length(xlbl),...
    'xticklabel', xlbl,'xticklabelrotation',45,...
    'ytick', 1:length(ylbl), 'yticklabel', ylbl,...
    'fontsize', 9, 'tickdir', 'out');

end