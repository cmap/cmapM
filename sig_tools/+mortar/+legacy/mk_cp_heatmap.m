function [cp_target,rev_ranks,ranks,mu_ge] = mk_cp_heatmap(scores,ge,cl,at_most)
% MK_CP_HEATMAP Gather top hit statistics for each biological target
% 
%   [cp_target,rev_ranks,ranks,mu_ge] = mk_cp_heatmap(scores,ge,cl,at_most)
%   will collapse ranks across replicates, pool together top ligand-target
%   interactions for each target, output replicate ranks, and the median
%   collapsed s2n or ge values. 
%   Inputs: 
%       scores - a p by screens matrix of LSS values
%       ge - a p by screens matrix of s2n or smm values
%       cl - a cell array specify biological target of each screen
%       at_most - a scalar. Indicates the top X to output in cp_target
%   Outputs: 
%       cp_target - a structure array with a dimension for each unique
%       target. Fields: 
%           'ix' : The indices of compounds in scores/ge, with length equal
%           to at_most
%           'scores': The scores matrix indexed by 'ix'
%           'target': a string. specifies target class
%           'mu_ge': The median s2n/smm values indexed by 'ix'
%   example run: 
%       [scores,mu_scores,bg_factor] =
%       get_smm_scores(smm_s2n,bio_factor,type) ; 
%       [cp_target,rev_ranks,ranks,mu_ge] =
%       mk_cp_heatmap(scores,smm_s2n,cl,at_most) ; 
%       figure, smm_heatmap(cp_target(2).mu_ge), title(cp_target(2).target)
% 
% see also get_smm_scores, mk_cp_heatmap, sep_smmfactors, run_smm_analysis
% 
% Author: Brian Geier, Broad 2010 

if nargin < 4
    at_most = 15; 
end
ranks = rankorder(scores,'direc','descend','dim',2);

classes = unique_ord(cl);
cp_target = struct('ix','','scores','','target','');

mu_ge = zeros(size(ge,1),length(classes));
for i = 1  : length(classes)
    mu_ge(:,i) = median(ge(:,strcmp(classes{i},cl)),2);
end

rev_ranks = zeros(size(ranks,1),length(classes));
for i = 1 : length(classes)
    list = median(ranks(:,strcmp(classes{i},cl)),2);
    rev_ranks(:,i) = rankorder(list);
    [~,keep] = sort(list);
    keep = keep(1:min(at_most,length(keep)));
    cp_target(i).ix = keep;
    cp_target(i).scores = scores(cp_target(i).ix,:);
    cp_target(i).target = classes{i};
    cp_target(i).mu_ge = mu_ge(cp_target(i).ix,:); 
end