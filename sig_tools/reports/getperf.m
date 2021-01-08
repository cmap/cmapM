function getperf(varargin)
% GETPERF  Evaluates/Outputs performance object for inference
%   GETPERF(varargin) will evaluate the ability to predict a given dataset
%   given a particular inference scheme. The analysis includes pearson and
%   spearman correlation between observed/inferred for both samplewise and
%   genewise cases, quantiles of these distributions, residuals, overall
%   residual measures, and pointwise outlier metric. 
%   Inputs: 
%       varargin : 
%           '-obs' : The observed dataset
%           '-inf' : The inferred counterpart, same dimensions as observed
%           '-out' : The output pathname for analysis
%           '-dep' : The dependent gene list (*.grp)
%   Outputs: 
%       A couple plots illustrating the outlier influence on correlation
%       measure. A single *.mat file which contains three data structures.
%           'corr_vals' : contains correlation
%           'dist' : contains mahal distance for each point in correlation
%           'perf' : overall performance measures, residuals, rmse is
%           currently the median absolute deviations
% 
% Author : Brian Geier, Broad 2010

spopen ; 

start = tic; 
% Check parameterss
dflt_out = get_lsf_submit_dir ; 
toolName = mfilename ; 
pnames = {'-obs','-inf','-out','-dep'}; 
dflts = {'','',dflt_out,''}; 
arg = parse_args(pnames,dflts,varargin{:}); 
print_args(toolName,1,arg); 
otherwkdir = mkworkfolder(arg.out, toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

% Get data
[inferred,gn,gd,sid] = parse_gct0(arg.inf);
dep = parse_grp(arg.dep); 
[~,Ldep] = intersect_ord(gn,dep); 

inferred = inferred(Ldep,:); 
[test,test_gn] = parse_gct0(arg.obs);
[~,Ldep_test] = intersect_ord(test_gn,dep); 
if length(Ldep) ~= length(Ldep_test)
    error('dep gene probes are not consistent');
end
test = test(Ldep_test,:); 
if ~isequal(test_gn(Ldep_test),gn(Ldep))
    [~,resort] = intersect_ord(gn(Ldep),test_gn(Ldep_test));
    test = test(resort,:);
end

fprintf('\n')

fprintf(1,'%s\n',horzcat('Getting performance object for ', num2str(sum(length(Ldep))),...
    ' dep set')); 

inferred(inferred<0) = 0 ; 
quantiles = [0.25 0.5 0.75]; % quantiles to output in performance object
num_samples = size(test,2); 
num_comparisons = length(Ldep); 
tic
%% Get gene wise performance measures
pearson = zeros(1,num_comparisons); 
spearman = zeros(size(pearson)); 
d = zeros(num_samples,num_comparisons) ; 
parfor i = 1 : num_comparisons
    pearson(i) = corr( test(i,:)',inferred(i,:)'); 
    spearman(i) = corr(test(i,:)',inferred(i,:)','type','spearman'); 
    d(:,i) = checkpt(test(i,:),inferred(i,:)); 
end
corr_vals.genewise.pearson = pearson ; 
corr_vals.genewise.spearman = spearman; 
dist.genewise = d ; 
fprintf(1,'%s\n',horzcat('Gene wise correlation computation took ',num2str(toc/60),...
    ' minutes.')); 

tic
pearson = zeros(1,num_samples); 
spearman = zeros(size(pearson)); 
d = zeros(num_comparisons,num_samples); 
%% Get per sample gene profile performance measures
parfor i = 1 : size(test,2) % num_samples
    pearson(i) = corr( test(:,i),inferred(:,i)); 
    spearman(i) = corr(test(:,i),inferred(:,i),'type','spearman'); 
    d(:,i) = checkpt(test(:,i),inferred(:,i)); 
end

corr_vals.samplewise.pearson = pearson;
corr_vals.samplewise.spearman = spearman; 
dist.samplewise = d ; 


fprintf(1,'%s\n',horzcat('Sample wise correlation computation took ',num2str(toc/60),...
    ' minutes.')); 


fprintf(1,'%s\n','Getting AUC and quantiles for all cases'); 
perf.genewise.pearson.quants = quantile(corr_vals.genewise.pearson,quantiles); 
[f,x] = ecdf(corr_vals.genewise.pearson); 
perf.genewise.pearson.auc = AUC(x,f); 
perf.samplewise.pearson.quants = quantile(corr_vals.samplewise.pearson,quantiles); 
[f,x] = ecdf(corr_vals.samplewise.pearson); 
perf.samplewise.pearson.auc = AUC(x,f);

perf.genewise.spearman.quants = quantile(corr_vals.genewise.spearman,quantiles); 
[f,x] = ecdf(corr_vals.genewise.spearman); 
perf.genewise.spearman.auc = AUC(x,f); 
perf.samplewise.spearman.quants = quantile(corr_vals.samplewise.spearman,quantiles); 
[f,x] = ecdf(corr_vals.samplewise.spearman); 
perf.samplewise.spearman.auc = AUC(x,f);

perf.genewise.rmse = sqrt(mean((test' - inferred').^2) ); 
perf.samplewise.rmse =  sqrt(mean((test - inferred).^2 )) ; 
perf.genewise.residual = test' - inferred'; 
perf.samplewise.residual =  test - inferred ;  


%% Save Output and Images

meta.sid = sid; 
meta.gn = gn(Ldep);
meta.gd = gd(Ldep); 
save(fullfile(arg.out,horzcat('perf_',pullname(arg.inf))),'perf',...
    'corr_vals','meta','dist'); 


print_str(horzcat('Computation took ',num2str(toc(start)/60))); 

end

function y = checkpt(x1,x2)

x = [x1(:) x2(:)]; 
sigma_val = cov(x); 
mu_val = mean(x); 
a = diag(sigma_val); 
sigma_inv = (1/det(sigma_val))*[ a(2) -1*sigma_val(1,2)  ; ...
    -1*sigma_val(2,1) a(1) ] ; 
y = (x-repmat(mu_val,[length(x1),1]))*sigma_inv*...
    (x-repmat(mu_val,[length(x1),1]))'; 
y = abs(diag(y)); 

end

function auc = AUC(x,y)
% Have enough data?
if length(x)<2
    auc = 0;
    return;
end

% Get area, from matlab function
auc = 0.5*sum( (x(2:end)-x(1:end-1)).*(y(2:end)+y(1:end-1)) );
auc = abs(auc);
end