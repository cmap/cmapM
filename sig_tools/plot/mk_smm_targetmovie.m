function aviobj = mk_smm_targetmovie(cp_target,fname,type)

bo_factor = cell(1,length(cp_target)); 
for i = 1 : length(bo_factor)
    bo_factor{i} = cp_target(i).target ; 
end

aviobj = avifile(fname);

aviobj.quality = 100; % Controls file size
aviobj.fps = 1 ; % Slide show speed

fig = findNewHandle(); 

for i = 1 : length(cp_target)
    figure(fig)
    if strcmp('heatmap',type)
        mit_heatmap(cp_target(i).scores)
        title(['Target = ',bo_factor{i}],'FontSize',14); 
        set(gca,'XTickLabel',bo_factor); 
        set(gca,'XTick',1:length(bo_factor)); 
        set(gca,'YTickLabel',{' '});
        set(gca,'FontSize',6);
        rotateticklabel(gca);
    else
        plot(cp_target(i).scores')
        title(['Target = ',bo_factor{i}],'FontSize',14); 
        set(gca,'XTickLabel',bo_factor); 
        set(gca,'XTick',1:length(bo_factor)); 
%         set(gca,'YTickLabel',{' '});
        set(gca,'FontSize',6);
        rotateticklabel(gca);
    end
    % Add frame to movie
    aviobj = addframe(aviobj,getframe(fig));
    
end
close(fig); 
aviobj = close(aviobj); 