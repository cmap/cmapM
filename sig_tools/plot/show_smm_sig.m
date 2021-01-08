classdef show_smm_sig
% A class implementation for showing the significant ligand-target
% interactions. subroutine in run_smm_analysis
% 
% see also run_smm_analysis
    properties
        scores ; 
        collapsed_scores ; 
        s2n ; 
        collapsed_s2n ; 
        bio_factor ; 
        cl ; 
        feature_names ; 
        out ; 
    end
    methods
        function data = gather_obj(s,cs,s2n,cs2n,bo,cl,features,out_dir)
            % all incoming matrices have been subsetted by some significant
            % features
            data.scores = s ; 
            data.collapsed_scores = cs ; 
            data.s2n = s2n ; 
            data.collapsed_s2n = cs2n ; 
            data.bio_factor = bo ; 
            data.cl = cl ; 
            data.feature_names = features ; 
            data.out = out_dir; 
        end
        
        function write_sig_set(data)
            % data is a structure with fields scores, collapsed_scores, s2n,
            % collapsed_s2n, feature names, bio_factor, cl (current bo)
            font_size = 14; 
            num_features = size(data.scores,1);
            classes = unique(data.bio_factor); 
            num_cl = length(classes) ; 
            h = findNewHandle();
            % line plots, including replicates
            for i = 1 : min(num_features,15)
                figure(h);
                idx = find(strcmp(data.cl,data.bio_factor)); 
                subplot(211) % s2n profile
                plot(data.s2n(i,:),'LineWidth',1.5)
                hold on ; 
                plot(idx,data.s2n(i,idx),'r.','MarkerSize',15)
                xlabel('Screen','FontSize',font_size);
                ylabel('Feature s2n','FontSize',font_size)
                title([dashit(drop_dots(data.feature_names{i})),' - S2N Profile'],...
                    'FontSize',font_size); 

                subplot(212) % scores profile
                plot(data.scores(i,:),'LineWidth',1.5)
                hold on ; 
                plot(idx,data.scores(i,idx),'r.','MarkerSize',15)
                xlabel('Screen','FontSize',font_size);
                ylabel('Feature LSS','FontSize',font_size)
                title([dashit(drop_dots(data.feature_names{i})),' - LSS Profile'],...
                    'FontSize',font_size); 
                orient landscape
                saveas(h,fullfile(data.out,[num2str(i),'_line']),'pdf') ; 
                subplot(211), cla(h); subplot(212), cla(h); 
            end
            close(h);
            h = findNewHandle();
            figure(h);
            smm_heatmap(data.collapsed_scores)
            set(gca,'XTick',1:length(classes),'XTickLabel',classes) 
            rotateticklabel(gca);
            if num_features <= 10
                set(gca,'YTick',1:num_features,'YTickLabel',data.feature_names); 
            end
            title([data.cl,' - collapsed LSS'],'FontSize',font_size); 

            orient landscape
            saveas(h,fullfile(data.out,[data.cl,'_lssheatmap']),'png'); 
            % saveas(h,fullfile(data.out,[data.cl,'_lssheatmap']),'pdf'); 
            cla(h);

            smm_heatmap(data.collapsed_s2n)
            set(gca,'XTick',1:length(classes),'XTickLabel',classes) 
            rotateticklabel(gca);
            if num_features <= 10
                set(gca,'YTick',1:num_features,'YTickLabel',data.feature_names); 
            end
            title([data.cl,' - collapsed s2n'],'FontSize',font_size); 
            orient landscape
            saveas(h,fullfile(data.out,[data.cl,'_s2nheatmap']),'png'); 
            % saveas(h,fullfile(data.out,[data.cl,'_s2nheatmap']),'pdf'); 
            cla(h); 


            g = cell(num_features,length(classes)); 
            for i = 1 : num_cl
                g(:,i) = repmat(classes(i),[num_features,1]); 
            end

            if num_features <= 10
                figure(h)
                lts_plot(reshape(data.collapsed_scores,[1,num_features*num_cl]),...
                    reshape(g,[1,num_features*num_cl]),'points')
                title({'Ligand Target Saliency',data.cl},'FontSize',font_size);
                xlabel('Ligand Score Statistic (median collapsed)','FontSize',font_size); 
                xlim([0,75])
                saveas(h,fullfile(data.out,[data.cl,'_scorelts']),'pdf'); 
                cla(h); 
                figure(h);
                lts_plot(reshape(data.collapsed_s2n,[1,num_features*num_cl]),...
                    reshape(g,[1,num_features*num_cl]),'points')
                title({'Ligand Target Saliency',data.cl},'FontSize',font_size);
                xlabel('Ligand S2N (median collapsed)','FontSize',font_size); 
                xlim([0,10])
                saveas(h,fullfile(data.out,[data.cl,'_s2nlts']),'pdf'); 
            else
                figure(h)
                lts_plot(reshape(data.collapsed_scores,[1,num_features*num_cl]),...
                    reshape(g,[1,num_features*num_cl]),'box')
                title({'Ligand Target Saliency',data.cl},'FontSize',font_size);
                xlabel('Ligand Score Statistic (median collapsed)','FontSize',font_size); 
                xlim([0,75])
                saveas(h,fullfile(data.out,[data.cl,'_scorelts']),'pdf'); 
                cla(h); 
                figure(h);
                lts_plot(reshape(data.collapsed_s2n,[1,num_features*num_cl]),...
                    reshape(g,[1,num_features*num_cl]),'box')
                title({'Ligand Target Saliency',data.cl},'FontSize',font_size);
                xlabel('Ligand S2N (median collapsed)','FontSize',font_size); 
                xlim([0,10])
                saveas(h,fullfile(data.out,[data.cl,'_s2nlts']),'pdf'); 
            end

            close(h);  

            end
    end
end 