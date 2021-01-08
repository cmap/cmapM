function mk_poscon_heatmap(ge,ranks,cl)

if size(ge,1) ~= length(ranks)
    error('!!')
end
font_size = 10; 

[~,map_sort] = sort(ranks);

figure
mit_heatmap(ge(map_sort,:))
set(gca,'FontSize',font_size)
set(gca,'YTickLabel',ranks(map_sort))
set(gca,'YTick',1:size(ge,1))
set(gca,'XTickLabel',cl)
set(gca,'XTick',1:length(cl))
rotateticklabel(gca);