function smm_rank_rtest(varargin)
% SMM_RANK_RTEST A Randomized Rank Permutation Test given SMM ranking
% 
%   SMM_RANK_RTEST(varargin) will run a monte carlo simulation to gauge the
%   randomness of observed ranks, given the median consensus rank. The test
%   is either done completely at random or teathered to a single observed
%   rank with other replicate ranks being at random. The testing procedure
%   is computationally intensive, and will benefit if run in parallel using
%   parallel toolbox. The parallel session is initialized if the toolbox is
%   installed, otherwise runs sequentially. 
%   Inputs: 
%       '-smm_ranks': the observed LSS-SMM ranks, including replicates, a
%       p-by-N matrix, where p=# ligands, N=# chemical screens
%       '-out': The output director
%       '-num_perms': The number of randomized experiments to perform. Each
%       random experiment simulation is carried out for each BO, resulting
%       in -num_perms*(# bo) flops. default = 500
%       '-type': The type of null distribution used, either completely
%       random ('full') or teathered to an observed rank ('partial')
%   Output: 
%       A p-value matrix is saved. The pvalue represents the proportion of
%       ranks greater than the observed rank, where the comparison is
%       carried out against the simulated ranks. 
%   Notes:
%       This implementation is best used with the matlab Parallel Toolbox,
%       otherwise this code should be compiled and LSF'ed . This code could
%       also be used on a generic rank matrix, as long as column sample
%       labels are consistent with smm convention. 
% 
% see also run_smm_analysis
% 
% Author: Brian Geier, Broad 2010

dflt_out = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-smm_ranks','-out','-num_perms','-type'}; 

dflts = {'',dflt_out,500,'partial'}; 

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 

otherwkdir = mkworkfolder(arg.out, toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

[ge,gn,gd,sid] = parse_gct0(arg.smm_ranks); 
[bio_factor,factor_sort] = sep_smmfactors(sid); 
if ~isequal(sid(factor_sort),sid)
    ge = ge(:,factor_sort) ;    
end
classes = unique(bio_factor);
num_classes = length(classes); 

cp_ranks_obs = zeros(size(ge,1),num_classes);
for i = 1 : num_classes
    cp_ranks_obs(:,i) = median(ge(:,strcmp(classes{i},bio_factor)),2); 
end
cp_ranks_pvalues = zeros(size(cp_ranks_obs)); 

switch arg.type
    case 'full'
        idx = rand(size(ge,1),size(ge,2),arg.num_perms); 
        [~,lists] = sort(idx,1);  
        cp_ranks_perm = zeros(size(cp_ranks_obs,1),size(cp_ranks_obs,2),...
            arg.num_perms);
        print_str('Running permutations...'); tic
        for i = 1 : arg.num_perms
            for j = 1 : num_classes
                cp_ranks_perm(:,j,i) = median(lists(:,strcmp(classes{j},bio_factor),i),2); 
            end
            cp_ranks_perm(:,:,i) = rankorder(cp_ranks_perm(:,:,i),'dim',2); 
        end
        toc
        print_str('Getting pvalues...');tic
        parfor i = 1 : num_classes
            tmp = cp_ranks_perm(:,i,:);
            cp_ranks_pvalues(:,i) = getpvalue(tmp(:),cp_ranks_obs(:,i)); 
        end
        toc
    case 'partial'
        % include an observed rank at random, remaining ranks are taken
        % from random lists 
        print_str('Running permutations'); tic ; 
        parfor i = 1 : num_classes
            cl = find(strcmp(classes{i},bio_factor)); 
            picks = randsample(cl,arg.num_perms,true); 
            idx = [reshape(ge(:,picks),[size(ge,1),...
                1,arg.num_perms]), rand(size(ge,1),...
                length(cl)-1,arg.num_perms)];
            cp_ranks_perm = zeros(size(idx,1),arg.num_perms); 
            for j = 1 : arg.num_perms
                cp_ranks_perm(:,j) = rankorder(median(rankorder(...
                    squeeze(idx(:,:,j)),'dim',2),2)); 
            end
            cp_ranks_pvalues(:,i) = getpvalue(cp_ranks_perm(:),cp_ranks_obs(:,i)); 
        end  
        
        toc
        
    otherwise
        error('unsupported')
end
mkgct0(fullfile(arg.out,[pullname(arg.smm_ranks),'_rank',arg.type,'_pvalues.gct']),...
    cp_ranks_pvalues,gn,gd,classes); 
mkgct0(fullfile(arg.out,[pullname(arg.smm_ranks),'_rank',arg.type,'_neglogpvalues.gct']),...
    -log10(cp_ranks_pvalues),gn,gd,classes);
