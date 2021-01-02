function plotModMap(x, title_str, name_str, showfig)
%%

myfigure(showfig)
imagescnan(x.mat, zsmap, get_color('grey'), [-10, 10])
axis square
if length(x.cid) < 50
    set(gca, 'xtick', 1:length(x.cid), 'xticklabel', texify(x.cid));
    th = rotateticklabel(gca, 45);
    set(th, 'fontsize', 8, 'fontweight', 'bold')
end
if length(x.rid)<50
    row_label = ds_get_meta(x, 'row', 'pert_iname');
    set(gca, 'ytick', 1:length(x.rid), 'yticklabel', texify(row_label),...
        'fontsize', 10, 'fontweight', 'bold');    
end

title(title_str);
xlabel('Cell line')
ylabel('Perturbagen')
grid off
namefig(name_str);

end