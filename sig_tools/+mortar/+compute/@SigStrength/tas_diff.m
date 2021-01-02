function res = tas_diff(ss_diff, cc_q75, nrep, use_absolute_scale)
% TAS_DIFF Compute transcriptional acivity score based on ss_diff
% RES = TAS_DIFF(SSD, CC_Q75, NREP, USE_ABS_SCALE) computes composite
% transcriptional activity scores based on signature strength (SSD),
% replicate correlation (CC_Q75) and number of replicates (NREP). The
% function assumes that SSD, CC_Q75 and NREP are vectors with the same
% dimensions RES is a structure array of length SSD with these fields:
% 'tas_gmean', 'tas_amean' and 'tas_rank' These values are computed as follows:
%
% TAS_GMEAN = sqrt(ADJ_SSD * ADJ_CC) / sqrt(MAX_SSD * MAX_CC)
%
% TAS_AMEAN = 0.5 * (ADJ_SSD / MAX_SSD + ADJ_CC / MAX_CC);
% where 
%       ADJ_SSD = SSD .* sqrt(NREP)
%       ADJ_CC = clip(CC_Q75, 0, 1)
% if USE_ABSOLUTE_SCALE is true
%       MAX_SSD = 20*nanmax(sqrt(NREP))
%       MAX_CC = 1;
% else
%       MAX_SSD = nanmax(ADJ_SSD)
%       MAX_CC = nanmax(ADJ_CC); 
%
% TAS_RANK = 0.5 * (SS_FRANK + CC_FRANK) where 
% SS_FRANK and CC_FRANK are the fractional ranks of ADJ_SSD and ADJ_CC
% respectively
% 

sqrt_nrep = sqrt(nrep(:));
% weight ssd by number of reps
adj_ssd = ss_diff(:).*sqrt_nrep;
% ignore negative cc values
adj_cc_q75 = clip(cc_q75(:), 0, 1);

if use_absolute_scale
    max_cc = 1;
    max_ssd = 20*nanmax(sqrt_nrep);
else
    % scale based on maxima within data
    max_cc = nanmax(adj_cc_q75);
    max_ssd = nanmax(adj_ssd);
end

% TAS based on cc and ss_diff
tas_amean = 0.5*(adj_ssd/max_ssd + adj_cc_q75/max_cc);

tas_gmean = sqrt(clip(adj_ssd,0.001,inf).*clip(adj_cc_q75, 0.001, inf))/sqrt(max_ssd * max_cc);

%% Rank based TAS
ss_frank = rankorder(adj_ssd, 'fixties', true, 'direc','ascend','as_fraction',true);
cc_frank = rankorder(adj_cc_q75, 'fixties', true, 'direc','ascend','as_fraction',true);
% TAS rank based 
tas_rank = 0.5*(ss_frank+cc_frank);
%%
res = struct('tas_gmean', num2cell(tas_gmean),...
             'tas_amean', num2cell(tas_amean),...
             'tas_rank', num2cell(tas_rank));
end