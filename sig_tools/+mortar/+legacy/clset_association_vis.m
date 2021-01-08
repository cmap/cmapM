classdef clset_association_vis
    properties 
        cl_names ; 
        posterior ; % probability of set i given cl j
    end
    methods
        function obj = clset_association_vis(c,p)
            obj.cl_names = c; 
            obj.posterior = p; 
        end
        function disp_significance(obj)
            num_sig_perbo = sum(obj.posterior>0);
            quants = [0.01,0.05,0.25,0.5,0.75,0.95,0.99];
            font_size = 12;
            [~,ix] = sort(num_sig_perbo);
            [f,x] = ecdf(num_sig_perbo); 
            subplot(121)
            stairs(x,f,'b','LineWidth',1.2); grid on 
            xlabel('x : # Sets with at least 1 member significant',...
                'FontSize',font_size); 
            ylabel('F(x)','FontSize',font_size); 
            title('Distribution of Significant Sets per class',...
                'FontSize',font_size); 
            set(gca,'FontSize',font_size); 
            idx = ix(ceil(length(ix).*quants)) ; 
            color = mkcolorspec(length(idx));
            subplot(122)
            hold on;
            for i = 1 : length(idx)
                plot(sort(obj.posterior(:,idx(i)),'descend'),color{i},...
                    'LineWidth',1.2)
            end
            grid on ; set(gca,'FontSize',font_size);
            lb = cell(size(idx)); 
            for i = 1 : length(lb)
                lb{i} = [obj.cl_names{idx(i)},', ',num2str(quants(i))]; 
            end
             
            legend(lb); 
            xlabel('Chemical Sets','FontSize',font_size); 
            ylabel('Proportion of Members Significant',...
                'FontSize',font_size); 
            title('Class - Set vignette','FontSize',font_size); 
            xlim([0,max(num_sig_perbo)+5]); 
            set(gca,'FontSize',font_size); 
        end
    end
end