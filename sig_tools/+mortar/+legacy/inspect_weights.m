function [auc_vals,sorted_weights] = inspect_weights(weights,gn,varargin)
% INSPECT_WEIGHTS   Inspect Weight Activity
%   [auc_vals,sorted_weights] = inspect_weights(weights,gn,varargin) will
%   create a visualization of the weight activity for a given model across
%   a set of input features. 
%   Inputs: 
%       weights: a q by p dependency matrix, outputted by train_model
%       gn : The predictor labels
%       varargin: 
%           'offset': logical indicator, whether or not a model offset is
%           present
%           'out': The output directory, default is pwd
%           'name': The output filename, default is weights
%   Outputs: 
%       An image of predictor activity across a set of dependent genes. 
% 
% see also mkweights
% 
% Author: Brian Geier, Broad 2010

isParallel = spopen ; 
if isParallel
    num_labs = 40;
else
    num_labs = 5; 
end

toolName = mfilename ; 
pnames = {'offset','out','name'};
dflts = {1,pwd,'weights'};
arg = parse_args(pnames,dflts,varargin{:}); 
print_args(toolName,1,arg); 

font_size = 15; 

if arg.offset
    visualizeweights(weights(:,2:end),'num_labs',num_labs); 
    
    auc_vals = zeros(size(weights,1),1);
    sorted_weights = sort(abs(weights(:,2:end)),2,'descend'); 
    parfor i = 1 : size(sorted_weights,1)
        auc_vals(i) = AUC((1:size(sorted_weights,2)-1)/(size(sorted_weights,2)-1),...
            sorted_weights(i,2:end)/max(sorted_weights(i,2:end)) ) ;
    end
    [sorted_lm_var,ix_s] = sort(std(weights(:,2:end)),'descend'); 
else
    visualizeweights(weights,'num_labs',num_labs);
    
    auc_vals = zeros(size(weights,1),1);
    sorted_weights = sort(abs(weights),'descend'); 
    parfor i = 1 : size(sorted_weights,1)
        auc_vals(i) = AUC((1:size(sorted_weights,2))/size(sorted_weights,2),...
            sorted_weights(i,:)/max(sorted_weights(i,:)) ) ;
    end
    [sorted_lm_var,ix_s] = sort(std(weights),'descend'); 
end
orient landscape
saveas(gcf,fullfile(arg.out,horzcat(arg.name,'_weights')),'pdf'); 
% Output summary plots

ecdf(weights(:,ix_s(1)))
hold on ; grid on ; 
xlabel('x : weight')
[f,x] = ecdf(weights(:,ix_s(end))); 
stairs(x,f,'r')
h = legend(horzcat('Most Active-',gn{ix_s(1)}),...
    horzcat('Least Active-',gn{ix_s(end)}),'Location','SouthEast'); 
set(h,'FontSize',font_size,'box','off'); 
orient landscape
saveas(gcf,fullfile(arg.out,horzcat(arg.name,'_MostLeastActive')),'pdf')


dep = randperm(size(weights,1)); 
landmarks = randperm(size(weights,2)) ;

figure
imagesc(abs(weights(dep(1:30),landmarks(1:30))))
xlabel('Landmark Weights','FontSize',font_size)
ylabel('Dependent Gene Model','FontSize',font_size)
colorbar
% set(gca,'FontSize',font_size)
orient landscape
saveas(gcf,fullfile(arg.out,horzcat(arg.name,'_weightSnapShot')),'pdf')

figure
plot(sorted_lm_var)
xlabel('Sorted by Landmark Weight Activity','FontSize',font_size)
ylabel('Landmark Weight Distribution Stdev','FontSize',font_size)
set(gca,'FontSize',font_size)
orient landscape
saveas(gcf,fullfile(arg.out,horzcat(arg.name,'_weightActivity')),'pdf')

figure
hist(auc_vals*100)
ylabel('Number of Dependent Gene Models','FontSize',font_size)
xlabel(horzcat('Percentage of Active Landmarks',...
    ', p=',num2str(size(weights,2))),'FontSize',font_size)
set(gca,'FontSize',font_size)
orient landscape
saveas(gcf,fullfile(arg.out,horzcat(arg.name,'_weightActivityPerPredGene')),'pdf')
