function smm_rpt(varargin)
% SMM_RPT       Write vignettes from smm structure/signifiance analysis
% 
%   SMM_RPT(varargin) will write a report testing the significance of
%   ligand target interactions. A target-ligand saliency plot given pvalues
%   per ligand is outputted, as well as compiled SAR results. 
% 
%   Inputs: 
%       '-lss': Ligand Statistic Scores, collapsed across replicates
%       '-lss_likeli': The product of chemical set member probabilities. A
%       measure of probability that a set is less than all other features. 
%       '-lss_pvalues': Significance output per feature, found via
%       simulation. 
%       '-chem_sets': gmx file of chemical sets
%       '-alpha_level': The rejection criteria, default = 0.01
%       '-ranks': The collapsed LSS ranks, consistent with lss
%       '-out': The output directory, default = submission dir
%   Outputs: 
%       Chemical set / BO-feature significance intersection. A global
%       ligand target saliency plot, only significant features. 
% 
% see also smm_rank_rtest, smm_sar_analysis, run_smm_analysis,
% get_smm_scores, lss_likelihood
% 
% Author: Brian Geier, Broad 2010

dflt_out = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-lss','-lss_likeli','-lss_pvalues','-chem_sets',...
    '-alpha_level','-ranks','-out'}; 
    
dflts = {'','','','',0.01,'',dflt_out};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 

otherwkdir = mkworkfolder(arg.out, toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

% warning off MATLAB:xlswrite:AddSheet % uncomment if using xlswrite()

[input.lss,input.features,~,input.classes] = parse_gct0(arg.lss); 
input.likelihood = parse_gct0(arg.lss_likeli); % columns are consistent with chem sets file
print_str('Warning :: lss_likeli input is assumed to have same column orientation as chemsets'); 
input.pvalues = parse_gct0(arg.lss_pvalues); 
input.ranks = parse_gct0(arg.ranks); 
input.lss = double(input.lss); 

chem_sets = parse_gmx(arg.chem_sets); 
num_classes = size(input.lss,2); 

sig = input.pvalues <= arg.alpha_level ; 

vals = [];
g = [];
for i = 1 : size(sig,2)
    vals = [vals  ; input.lss(sig(:,i),i)];
    g = [g, repmat(input.classes(i),[1,sum(sig(:,i))])]; 
end
h = findNewHandle(); 
figure(h); 
lts_plot(vals,g);
title({'Ligand-Target Saliency',[dashit(pullname(arg.lss)),' - alpha=',...
    num2str(arg.alpha_level)]})
xlabel('Ligand Statistic Score')
saveas(h,fullfile(otherwkdir,'tls_box'),'pdf'); 
close(h); 


post_assign = assign_sets(input.likelihood,chem_sets,input.classes,...
    input.features,10); 
fid = fopen(fullfile(otherwkdir,'smm_report.txt'),'w');
fprintf(fid,'%s,%s,%s,%s,%s,%s,%s,\n','bo_name','cluster_name',...
    'feature_name','lss','P(LSS < lss)','LSS_rank','rank_pvalue'); 
for i = 1 : length(post_assign)
    d = compile_sheet(post_assign(i),input.lss(:,i),input.ranks(:,i),...
        input.pvalues(:,i)); 
    try % Write formatted sheet to .txt file (change to xlswrite if available)
        fid = write_report(d,fid,input.classes{i}); 
    catch em
        disp(em)
        fprintf(1,'%s\n',['Failed to write... ',input.classes{i}]); 
    end
end
fclose(fid); 

% Output vignette for chemical set activity
chem_set_sig = zeros(length(chem_sets),num_classes); % store median signifiance
for i = 1 : size(chem_set_sig,1)
    [~,list] = intersect_ord(input.features,chem_sets(i).entry); 
    for j = 1 : num_classes
        chem_set_sig(i,j) = median(input.pvalues(list,j)); 
    end
end
% Display
figure(h)
[n,x] = hist(chem_set_sig,10);
bar(x,(n/length(chem_sets))*100,1)
xlim([0,0.1])
ylabel('% of chemical sets')
xlabel('Median Ligand Rank Significance')
title({['Significant Ligand (p=',num2str(size(input.lss,1)),...
    ') and Chemical Set (n=',num2str(length(chem_sets)),') Activity'],...
    ['alpha = ',num2str(arg.alpha_level)]})
orient landscape
saveas(h,fullfile(otherwkdir,'chem_set_sig'),'pdf')
close(h); 
end

function fid = write_report(d,fid,cl)
format = {'%s,','%s,','%g,','%g,','%u,','%g,'};

for i = 2 : size(d,1)
    fprintf(fid,'%s,',cl); 
    for j = 1 : size(d,2)
        fprintf(fid,format{j},d{i,j}); 
    end
    fprintf(fid,'\n'); 
end


end

function d = compile_sheet(post_assign,lss,ranks,pvalues) % format data

num_sets = length(post_assign.clusters); 
lss_vals = [];
lss_ecdf_lookup = [];
rank_vals = [];
p_vals = [];

feature_labels = [];
cluster_labels = [];
for i = 1 : num_sets
    lss_vals = [lss_vals ; lss(post_assign.clusters(i).idx)];
    lss_ecdf_lookup = [lss_ecdf_lookup ; getpvalue(lss,...
        lss(post_assign.clusters(i).idx))]; 
    rank_vals = [rank_vals ; ranks(post_assign.clusters(i).idx)];
    p_vals = [p_vals ; pvalues(post_assign.clusters(i).idx)]; 
    feature_labels = [feature_labels ; post_assign.clusters(i).members(:)];
    cluster_labels = [cluster_labels ; repmat({post_assign.clusters(i).name},...
        [length(post_assign.clusters(i).idx),1])]; 
end
d = cell(length(lss_vals)+1,6); 
d{1,1} = 'cluster_name'; d{1,2} = 'feature_name' ; d{1,3} = 'lss' ; 
d{1,4} = 'P(LSS < lss)' ; d{1,5} = 'LSS_rank'; d{1,6} = 'rank_pvalue'; 

for i = 1 : length(lss_vals)
    clust_lab = cluster_labels{i}; 
    d{i+1,1} = clust_lab{1} ; 
    d{i+1,2} = feature_labels{i} ; 
    d{i+1,3} = lss_vals(i); 
    d{i+1,4} = lss_ecdf_lookup(i); 
    d{i+1,5} = rank_vals(i); 
    d{i+1,6} = p_vals(i); 
end


end

function post_assign = assign_sets(likeli,chem_sets,bo_names,feature_labels,top)

cluster_names = cell(length(chem_sets),1); 
for i = 1 : length(chem_sets)
    cluster_names{i} = chem_sets(i).head ; 
end

post_assign = struct('bo','','clusters',struct('name','',...
    'idx','','members','')); 
for i = 1 : size(likeli,2)
    [~,list] = sort(likeli(:,i),'descend'); list = list(1:top) ;
    post_assign(i).bo = bo_names{i};     
    for j = 1 : top
        [~,keep] = intersect_ord(feature_labels,chem_sets(list(j)).entry); 
        post_assign(i).clusters(j).idx = keep(:); 
        post_assign(i).clusters(j).members = feature_labels(keep);
        post_assign(i).clusters(j).name = cluster_names(list(j)); 
    end
end

end