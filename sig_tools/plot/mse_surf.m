function mse_surf(varargin)
% MSE_SURF  Compares feature selection versus random in context of leave
% out test prediction error
%   mse_surf(varargin) will compare a feature selection algorithm vs.
%   random selection. Results are outputted in the context of leave out
%   test prediction error, and are drawn as a line plot given # landmarks
%   in model training. Analysis is only ran on a random subset of dependent
%   gene models, as there output is assessed separately. 
%   Inputs: 
%       '-train': The training dataset, gct
%       '-ratios': A matlab object with variable t_ratios. The variable 
%       t_ratios is a matrix of feature statistic
%       scores with dimensions #dependent genes by #landmark features
%       '-out': The output directory, default=submission dir
%       '-num_check': The number of dependent models to check, go low for
%       faster run-time. 
%       '-dep': The dependent genes, grp
%       '-lm': The landmark genes, grp
%   Output: 
%       Line plots comparing the test error given random landmark subset
%       and feature selection algorithm choice. 
% see also

start = tic  ;
spopen ; 

dflt_out = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-train','-ratios','-out','-num_check','-dep','-lm'}; 

dflts = {'','',dflt_out,'','',''};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 
otherwkdir = mkworkfolder(arg.out, toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 
landmarks = parse_grp(arg.lm); 
dep = parse_grp(arg.dep); 

[ge,gn,~,sid] = parse_gct0(arg.train); 
if ~isempty(arg.ratios)
    load(arg.ratios); % landmarks, dep, t_ratios (+-)
% else
%     t_ratios = rand(length(dep),length(landmarks)+1); % random choice
end
rand_ratios = rand(length(dep),length(landmarks)+1); 
regf = @(XTRAIN,ytrain,XTEST)(train_model(ytrain,XTRAIN,'lsnull')*XTEST);

% n = 100:100:length(sid); 
lm = 10:30:length(landmarks); 

[~,Ldep] = intersect_ord(gn,dep); 
[~,L] = intersect_ord(gn,landmarks); 
y = double(ge(Ldep,:)'); X = double(ge(L,:)'); 

pick = randsample(1:size(y,2),str2double(arg.num_check),false); 

y = y(:,pick); % only do a subset of dependent gene models
rmse_pts = zeros(size(y,2),length(lm)); 
rmse_pts_rand = zeros(size(rmse_pts)); 
t_ratios = t_ratios(pick,:); 
rand_ratios = rand_ratios(pick,:); 
[~,lm_idx] = sort(abs(t_ratios),2,'descend'); 
[~,rand_idx] = sort(rand_ratios,2,'descend'); 

X = [ones(length(sid),1),X]; 
h = waitbar(0,'Running landmark configurations...'); 
for i = 1 : size(y,2)
    y_step = y(:,i);
    for j = 1 : length(lm)
        x_step = X(:,lm_idx(i,1:lm(j))); 
        x_step_rand = X(:,rand_idx(i,1:lm(j))) ;
        partitions = cvpartition(length(y_step),'holdout',0.2); 
        rmse_pts(i,j) = rmse(y_step(partitions.test),...
            regf(x_step(partitions.training,:)',y_step(partitions.training)',...
            x_step(partitions.test,:)')'); 
        rmse_pts_rand(i,j) = rmse(y_step(partitions.test),...
            regf(x_step_rand(partitions.training,:)',y_step(partitions.training)',...
            x_step_rand(partitions.test,:)')');
    end
    figure
    plot(lm,rmse_pts(i,:),'r','LineWidth',1.5)
    hold on 
    plot(lm,rmse_pts_rand(i,:),'g','LineWidth',1.5)
    h_l = legend('FSB','RND'); 
    set(h_l,'FontSize',14); 
    plot(lm,rmse_pts(i,:),'.','MarkerSize',15)
    plot(lm,rmse_pts_rand(i,:),'.','MarkerSize',15)
    xlabel('# Landmarks','FontSize',14); 
    ylabel('Validation Test RMSE','FontSize',14)
    title(['Validation Run for ',dashit(dep{pick(i)}),' CV=',num2str(cv(y_step'))],'FontSize',14) 
    grid on 
    orient landscape
    saveas(gcf,fullfile(otherwkdir,[dep{pick(i)},'_valerror']),'pdf')
    close
    waitbar(i/size(y,2),h); 
end
close(h); 
fprintf(1,'%s\n',['Computation took ... ',num2str(toc(start)/60),' minutes.']); 
save(fullfile(otherwkdir,[pullname(arg.train),'_mse-surf']),'rmse_pts','arg','lm',...
    'pick','rmse_pts_rand') ;
fprintf(1,'%s\n',['Saved error evaluation to ',...
    fullfile(otherwkdir,[pullname(arg.train),'_mse-surf.mat'])]);
       
