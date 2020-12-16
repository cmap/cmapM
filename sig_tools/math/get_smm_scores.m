function [scores,mu_scores,bg_factor] = get_smm_scores(smm_s2n,bio_factor,type)
% GET_SMM_SCORES    Compute LSS from SMM S2N matrix
% 
%   [scores,mu_scores,bg_factor] = get_smm_scores(smm_s2n,bio_factor,type)
%   will convert the signal-to-noise smm data to a ligand statistic score
%   (LSS) matrix. The LSS can either be the 'chi_square' or 'zscore' type
%   with the former being preferred (default). The minimum scale factor per
%   ligand is 0.05. The scale factor per ligand is the 15% trimmed mean.
%   Additionally, the median collapsed LSS and scale factors are returned. 
% 
% see also run_smm_analysis
% 
% Author: Brian Geier, Broad 2010

if nargin < 3
    type = 'chi_square'; 
end

switch type
    case 'chisquare' % current standard for ligand prioritization
        scores = zeros(size(smm_s2n)) ; 
        bg_factor = trimmean(smm_s2n,.15,2); 
        for i = 1 : size(smm_s2n,1)
            bg_factor(i) = max(bg_factor(i),.05); 
            scores(i,:) = ( smm_s2n(i,:) - bg_factor(i) ) .^2 / bg_factor(i); 
        end
    case 'zscore' % zscore hasn't empirically shown good utility
        scores = zscore(smm_s2n')'; 
        bg_factor = [mean(smm_s2n,2),std(smm_s2n,0,2)];
    case 'foo'
        % add new metric here
        error('foo is not a metric');
    otherwise
        error('unsupported LSS');
end
        

classes = unique(bio_factor);
mu_scores = zeros(size(scores,1),length(classes)); 
for i = 1 : size(mu_scores,2)
    mu_scores(:,i) = median(scores(:,strcmp(classes{i},bio_factor)),2); 
end