function ensemble_pred(varargin)

dflt_out = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-infer','-weights','-out'};

dflts = {'','',dflt_out};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 
isParallel = spopen ; 
% 
% otherwkdir = mkworkfolder(arg.out, toolName); 
% fprintf('Saving analysis to %s\n',otherwkdir); 
% fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
% print_args(toolName,fid,arg); 
% fclose(fid); 
fprintf(1,'%s\n','Loading ensemble weights...'); 
ensemble_mat = load(arg.weights) ; 
num_ensembles = size(ensemble_mat.weights,3); 
[ge,gn,gd,sid] = parse_gct0(arg.infer);
[~,L] = intersect_ord(gn,ensemble_mat.landmarks); 
[~,Ldep] = intersect_ord(gn,ensemble_mat.dep); 
n = size(ge,2); 
yhat = zeros(length(Ldep),n,num_ensembles); 
fprintf(1,'%s\n','Making ensemble prediction...'); 
for i = 1 : num_ensembles
    if size(ensemble_mat.weights,2) == length(L)+1
        yhat(:,:,i) = squeeze(ensemble_mat.weights(:,:,i))*[...
            ones(1,n) ; ge(L,:)];
    else
        yhat(:,:,i) = squeeze(ensemble_mat.weights(:,:,i))*ge(L,:);
    end
end

if isParallel
    tmp = zeros(size(yhat,1),size(yhat,2)); 
    parfor i = 1 : size(tmp,1)
        tmp(i,:) = median(squeeze(yhat(i,:,:)),2); 
    end
    yhat = tmp; 
else
    yhat = mean(yhat,3); 
end

if isempty(setdiff(gn,[ensemble_mat.landmarks',ensemble_mat.dep']))
    inf = rearrangerows([ge(L,:) ; yhat],L,L_dep); 
else
    [~,remaining] = intersect_ord(gn,setdiff(gn,[...
        ensemble_mat.landmarks',ensemble_mat.dep'])); 
    inf = rearrangerows([ge(L,:) ; yhat ; ge(remaining,:)],L,Ldep,remaining);
end

mkgct0(fullfile(arg.out,['inf_',pullname(arg.infer),'_',...
    pullname(arg.weights),'.gct']),inf,gn,gd,sid,4); 