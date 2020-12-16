function [s2n_vals,s2n_pvals,fdr_pvals] = detect_hairpins(data,cl,pert,sample_tags)
% DETECT_HAIRPINS Hairping selection using simulation
%   detect_hairpins(data,cl,pert,sample_tags) will return the
%   signal-to-noise, computed as t-statistic with unequal variance, a
%   p-value found from permutation, and a p-value with respect to all
%   features, can be used as an initial first pass selection followed by
%   significance testing at feature level. Only supports two populations
%   
%   Inputs:
%       data - a hairpin by sample data matrix
%       cl - a k-element cell array, each element specifies a class, e.g.
%       cell line condition
%       pert - a 2-element cell array, each element corresponds to a
%       population, e.g. {'DMSO','High'}
%       sample_tags - a structure returned by tags2info(sid), corresponding
%       to samples in data
%   Outputs: 
%       s2n_vals - a hairpin by #(cell line) data matrix, the (i,j) element
%       being the signal-to-noise value for feature i in cell line j. The
%       order j is determined by the order of cl
%       s2n_pvals - pert labels are randomly scrambled 1000 times for each
%       feature independently, s2n computed for each time, the p-value then
%       represents an ECDF lookup of observed value in random permutations
%       for that feature
%       fdr_pvals - a refernce p-value, labels are scrambled for each
%       feature indepdently a single time, s2n is computed, then the an
%       ECDF lookup is performed with the observed values - an initial
%       screening p-value
% 
%   for example: 
%       [ge,gn,gd,sid] = parse_gct0(foo_data); % sid is CMAP formatted
%       % sid has fields 'pert' and 'cell'
%       [s2n_vals,s2n_pvals,fdr_pvals] =
%       detect_hairpins(ge,{'foo1','foo2'},{'DMSO','LOW'},tags2info(sid));
% 
% see also tags2info, hairpin_vis, getpvalue, ecdf
% 
% Author: Brian Geier, Broad 2010

fun = @(x,y) (mean(x,2)-mean(y,2))./...
    ( sqrt( var(x,0,2)/size(x,1) + var(y,0,2)/size(y,1) ) ) ;

isParallel = spopen();

s2n_vals = zeros(size(data,1),length(cl)); figure ;

for i = 1 : length(cl)
    cell_idx = strcmp(cl{i},sample_tags.cell); 
    s2n_vals(:,i) = fun(data(:,strcmp(pert{1},sample_tags.pert) & cell_idx),...
        data(:,strcmp(pert{2},sample_tags.pert)&cell_idx)); 
end

num_perms = 1000;
s2n_vals_perm = zeros(size(data,1),length(cl),num_perms);
for i = 1 : length(cl)
    cell_idx = strcmp(cl{i},sample_tags.cell); 
    A = data(:,strcmp(pert{1},sample_tags.pert)&cell_idx) ; 
    B = data(:,strcmp(pert{2},sample_tags.pert)&cell_idx) ; 
    step = [A,B]; sample_size = floor(size(step,2)/2);
    [~,label_idx] = sort(rand(size(step,2),num_perms)); 
    if isParallel
        parfor j = 1 : num_perms
            s2n_vals_perm(:,i,j) = fun(step(:,label_idx(1:sample_size,j)),...
                step(:,label_idx(sample_size+1:end,j))); 
        end 
    else
        h =waitbar(0,'permutting s2n..');
        for j = 1 : num_perms
            s2n_vals_perm(:,i,j) = fun(step(:,label_idx(1:sample_size,j)),...
                step(:,label_idx(sample_size+1:end,j))); 
            waitbar(j/num_perms,h); 
        end ; close(h);
    end
end 

s2n_pvals = zeros(size(s2n_vals)); num_features = size(s2n_vals,1); 
fdr_pvals = zeros(size(s2n_pvals)); 

for j = 1 : length(cl)
    if isParallel
        print_str(['Running ',cl{j}])
        parfor i = 1 : num_features
            s2n_pvals(i,j) = getpvalue(squeeze(s2n_vals_perm(i,j,:)),s2n_vals(i,j)); 
        end  
    else
        h = waitbar(0,'running pvals'); 
        for i = 1 : num_features
            s2n_pvals(i,j) = getpvalue(squeeze(s2n_vals_perm(i,j,:)),s2n_vals(i,j)); 
            waitbar(i/num_features,h); 
        end  
        close(h);
    end
    tmp = squeeze(s2n_vals_perm(:,j,1)); 
    steps = reshape(1:size(s2n_vals,1),[size(s2n_vals,1)/5,5]); 
    for k = 1 : 5
        fdr_pvals(steps(:,k),j) = getpvalue(tmp(:),s2n_vals(steps(:,k),j)); 
    end
end


