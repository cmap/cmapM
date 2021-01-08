function svm_obj = train_svm(dependent,landmarks,dep,sid,varargin)
% Prototype code for building support vector regression model

% toolName = mfilename ; 

pnames = {'-kernel','-bandwidth','-num_exemplars'};

dflts = {'linear',0,300}; 
 
arg = parse_args(pnames,dflts,varargin{:}); 

% start = tic; 
% print_args(toolName,1,arg); 
% otherwkdir = mkworkfolder(arg.out, toolName); 
% fprintf('Saving analysis to %s\n',otherwkdir); 
% fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
% print_args(toolName,fid,arg); 
% fclose(fid); 

% arg.bandwidth = str2double(arg.bandwidth);

[num_models,n] = size(dependent);
landmarks = zscore(landmarks');
dependent = dependent';


svm_obj = struct('model',struct('submodel',...
    struct('nsv','','beta','','bias',''),'probe_id',''),...
    'kernel',arg.kernel,'bandwidth',arg.bandwidth);

h = waitbar(0,'Building SVM object...');
% arg.num_exemplars = 500;

for i = 1 :  num_models
    
    ix = randperm(n);
    [nsv,beta,bias] = svr(landmarks(ix(1:arg.num_exemplars),:),...
        dependent(ix(1:arg.num_exemplars),i),arg.kernel,arg.bandwidth);
    svm_obj.model(i).submodel(1).nsv = nsv ; 
    svm_obj.model(i).submodel(1).beta = beta ; 
    svm_obj.model(i).submodel(1).bias = bias ; 
    svm_obj.model(i).submodel(1).sample_train_idx = sid(ix(1:arg.num_exemplars));
    
    [nsv,beta,bias] = svr(landmarks(ix(arg.num_exemplars+1:2*arg.num_exemplars),:),...
        dependent(ix(arg.num_exemplars+1:2*arg.num_exemplars),i),arg.kernel,arg.bandwidth);
    svm_obj.model(i).submodel(2).nsv = nsv ; 
    svm_obj.model(i).submodel(2).beta = beta ; 
    svm_obj.model(i).submodel(2).bias = bias ; 
    svm_obj.model(i).submodel(2).sample_train_idx = ...
        sid(ix(arg.num_exemplars+1:2*arg.num_exemplars));
    
    [nsv,beta,bias] = svr(landmarks(ix(2*arg.num_exemplars+1:3*arg.num_exemplars),:),...
        dependent(ix(2*arg.num_exemplars+1:3*arg.num_exemplars),i),arg.kernel,arg.bandwidth);
    svm_obj.model(i).submodel(3).nsv = nsv ; 
    svm_obj.model(i).submodel(3).beta = beta ; 
    svm_obj.model(i).submodel(3).bias = bias ; 
    svm_obj.model(i).submodel(3).sample_train_idx = ...
        sid(ix(2*arg.num_exemplars+1:3*arg.num_exemplars));
    
    waitbar(i/num_models,h);
    svm_obj.model(i).probe_id = dep{i};
    
end
close(h);
    
svm_obj.run_time = toc(start);
    
    
