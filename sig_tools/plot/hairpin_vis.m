function [results,handles,perm_stats] = hairpin_vis(data,cl,pert,sample_tags,cv_vals,fdr_pvals,s2n_pvals,s2n_vals)
% routine for evaluting hairpin experiment, in support of Jinyan
% Author: B. Geier
if nargin == 5
    [s2n_vals,s2n_pvals,fdr_pvals] = detect_hairpins(...
        data,cl,pert,sample_tags) ; 
    perm_stats.s2n_vals = s2n_vals ; 
    perm_stats.s2n_pvals = s2n_pvals ;
    perm_stats.fdr_pvals = fdr_pvals ;
elseif nargin ~= 8
    error('Check input arguments!');
else
    perm_stats.s2n_vals = s2n_vals ; 
    perm_stats.s2n_pvals = s2n_pvals ;
    perm_stats.fdr_pvals = fdr_pvals ;
end

start = findNewHandle();
fdr_thresh = 0.10 ;
pval_thresh = 0.01;
results = struct('up','','down',''); 

font_size = 12; 

% downward effect
%try 
    for i = 1 : length(cl)
        figure
        look = fdr_pvals(:,i) <= fdr_thresh; 
        x = s2n_pvals(look,i) ; y = fdr_pvals(look,i); z = squeeze(cv_vals(look,i)); 

        plot3(x,y,z*100,'.','MarkerSize',15); axis tight, grid on 
        set(gcf,'Name',[cl{i},'_FSspace_down']); orient landscape
        hold on ; 
        plot3(x( x < pval_thresh ),y(x < pval_thresh ),...
            z( x < pval_thresh )*100,'g.','MarkerSize',15)
        xlabel('Permuted P-values'); ylabel('ref-pval'); zlabel('%CV')
        title(['Feature Selection Space for ',cl{i}],'FontSize',font_size); 
        legend('de-prioritized','selected')
        % select picks
        look = find(look); 
        picks = look(x < pval_thresh ); 
        y = fdr_pvals(picks,i);
        [~,list] = sort(y); 
        picks = picks(list); 

        B = data(picks,strcmp(pert{2},sample_tags.pert)&strcmp(cl{i},...
            sample_tags.cell)); 
        A = data(picks,strcmp(pert{1},sample_tags.pert)&strcmp(cl{i},...
            sample_tags.cell)); 

        figure, mit_heatmap(scaleinput([B,A]')')
        colormap bluepink
        colorbar
        labels = [repmat(pert(2),[1,sum(strcmp(pert{2},sample_tags.pert)&...
            strcmp(cl{i},sample_tags.cell))]),...
            repmat(pert(1),[1,sum(strcmp(pert{1},sample_tags.pert)&...
            strcmp(cl{i},sample_tags.cell))])]; 
        set(gca,'XTickLabel',labels,'XTick',1:length(labels))
        title(['Selected features for ',cl{i}],'FontSize',font_size); 
        ylabel('Selected Probes - Sorted by evidence','FontSize',font_size)
        set(gcf,'Name',[cl{i},'_selected_hm_down']); orient tall

        figure
        plot(scaleinput([B,A]'))
        set(gca,'XTickLabel',labels,'XTick',1:length(labels))
        ylabel('Cell Viability - [-1,+1] probe mapped','FontSize',font_size)
        title(['Selected features response for ',cl{i}],...
            'FontSize',font_size); 
        set(gcf,'Name',[cl{i},'_selected_lp_down']); orient landscape

        results(i).down.cl = cl{i}; 
        results(i).down.A_label = pert{1}; 
        results(i).down.B_label = pert{2}; 
        results(i).down.A = A; 
        results(i).down.B = B; 
        results(i).down.idx_picks = picks; 
        results(i).s2n_vals = s2n_vals(:,i); 
    end

    t = [2,1]; 
    for i = 1 : length(cl)  % check hairpin cell line selectivity 

        figure, hold on
        [N,X] = hist(s2n_vals(results(i).down.idx_picks,i),30); 
        bar(X,N,1)
        [N,X] = hist(s2n_vals(results(t(i)).down.idx_picks,i),30); 
        bar(X,N,1,'r')
        xlabel('Fold Change','FontSize',font_size)
        ylabel('Count','FontSize',font_size)
        legend(cl{i},cl{t(i)})
        title(['FoldChange Distribution for ',cl{i},' picks'],...
            'FontSize',font_size)
        set(gca,'FontSize',font_size)
        orient landscape
        set(gcf,'Name',[cl{i},'_foldchange_dist_down']); 

    end

    % upward effect

    fdr_thresh = 0.01 ;

    for i = 1 : length(cl)
        figure
        look = fdr_pvals(:,i) >= 1-fdr_thresh; 
        x = s2n_pvals(look,i) ; y = fdr_pvals(look,i); z = squeeze(cv_vals(look,i)); 

        plot3(x,y,z*100,'.','MarkerSize',15); axis tight, grid on 
        set(gcf,'Name',[cl{i},'_FSspace_up']); orient landscape
        hold on ; 
        plot3(x( x > 1- pval_thresh),y(x > 1- pval_thresh),z( x > 1- pval_thresh)*100,'g.','MarkerSize',15)
        xlabel('Permuted P-values'); ylabel('ref-pval'); zlabel('%CV')
        title(['Feature Selection Space for ',cl{i}],'FontSize',font_size); 
        legend('de-prioritized','selected')
        % select picks
        look = find(look); 
        picks = look(x > 1- pval_thresh); 
        y = fdr_pvals(picks,i); 
        [~,list] = sort(y); 
        picks = picks(list); 

        B = data(picks,strcmp(pert{2},sample_tags.pert)&strcmp(cl{i},...
            sample_tags.cell)); 
        A = data(picks,strcmp(pert{1},sample_tags.pert)&strcmp(cl{i},...
            sample_tags.cell)); 

        figure, mit_heatmap(scaleinput([B,A]')')
        colormap bluepink
        colorbar
        set(gca,'XTickLabel',[repmat(pert(2),[1,sum(strcmp(pert{2},sample_tags.pert)&...
            strcmp(cl{i},sample_tags.cell))]),...
            repmat(pert(1),[1,sum(strcmp(pert{1},sample_tags.pert)&...
            strcmp(cl{i},sample_tags.cell))])])
        title(['Selected features for ',cl{i}],'FontSize',font_size); 
        ylabel('Selected Probes - Sorted by evidence','FontSize',font_size)
        set(gcf,'Name',[cl{i},'_selected_hm_up']); orient tall

        figure
        plot(scaleinput([B,A]'))
        set(gca,'XTickLabel',[repmat(pert(2),[1,sum(strcmp(pert{2},sample_tags.pert)&...
            strcmp(cl{i},sample_tags.cell))]),...
            repmat(pert(1),[1,sum(strcmp(pert{1},sample_tags.pert)&...
            strcmp(cl{i},sample_tags.cell))])])
        ylabel('Cell Viability - [-1,+1] probe mapped','FontSize',font_size)
        title(['Selected features response for ',cl{i}],...
            'FontSize',font_size); 
        set(gcf,'Name',[cl{i},'_selected_lp_up']); orient landscape

        results(i).up.cl = cl{i}; 
        results(i).up.A_label = pert{1}; 
        results(i).up.B_label = pert{2}; 
        results(i).up.A = A; 
        results(i).up.B = B; 
        results(i).up.idx_picks = picks; 
    end

    t = [2,1]; 
    for i = 1 : length(cl)

        figure, hold on
        [N,X] = hist(s2n_vals(results(i).up.idx_picks,i),30); 
        bar(X,N,1)
        [N,X] = hist(s2n_vals(results(t(i)).up.idx_picks,i),30); 
        bar(X,N,1,'r')
        xlabel('Fold Change','FontSize',font_size)
        ylabel('Count','FontSize',font_size)
        legend(cl{i},cl{t(i)})
        title(['FoldChange Distribution for ',cl{i},' picks'],...
            'FontSize',font_size)
        set(gca,'FontSize',font_size)
        orient landscape
        set(gcf,'Name',[cl{i},'_foldchange_dist_up']); 
    end

    handles = start:(findNewHandle()-1);
% %catch em
%     disp(em)
%     handles = [];
%     results=[];
% end