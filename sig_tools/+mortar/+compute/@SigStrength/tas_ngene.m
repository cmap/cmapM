function res = tas_ngene(ss_ngene, cc_q75, nrep, use_absolute_scale)
% TAS Compute transcriptional acivity score
% RES = TAS_NGENE(SSN, CC_Q75, NREP, USE_ABS_SCALE) computes composite
% transcriptional activity scores based on signature strength (SSN),
% replicate correlation (CC_Q75) and number of replicates (NREP). The
% function assumes that SSN, CC_Q75 and NREP are vectors with the same
% dimensions RES is a structure array of length SSN with two fields:
% 'tas_gmean', 'tas_amean' and 'tas_rank' These values are computed as
% follows:
%
% TAS_GMEAN = sqrt(ADJ_SSN * ADJ_CC) / sqrt(MAX_SSN * MAX_CC)
%
% TAS_AMEAN = 0.5 * (ADJ_SSN / MAX_SSN + ADJ_CC / MAX_CC);
% where 
%       ADJ_SSN = SSN .* sqrt(NREP)
%       ADJ_CC = clip(CC_Q75, 0, 1)
% if USE_ABSOLUTE_SCALE is true
%       MAX_SSN = 978*nanmax(sqrt(NREP))
%       MAX_CC = 1;
% else
%       MAX_SSN = nanmax(ADJ_SSN)
%       MAX_CC = nanmax(ADJ_CC); 
%
% TAS_RANK = 0.5 * (SS_FRANK + CC_FRANK) where 
% SS_FRANK and CC_FRANK are the fractional ranks of ADJ_SSN and ADJ_CC
% respectively
% 

assert(isequal(size(ss_ngene), size(cc_q75)), ...
    'ss_ngene [%dx%d] and cc_q75 [%dx%d] should have the same dimensions', ...
    size(ss_ngene, 1), size(ss_ngene,2), size(cc_q75, 1), size(cc_q75, 2))

sqrt_nrep = sqrt(nrep(:));
% weight SSN by number of reps
adj_ssn = ss_ngene(:).*sqrt_nrep;
% ignore negative cc values
adj_cc_q75 = clip(cc_q75(:), 0, 1);

if use_absolute_scale
    max_cc = 1;
    max_ssn = 978*nanmax(sqrt_nrep);
else
    % scale based on maxima within data
    max_cc = nanmax(adj_cc_q75);
    max_ssn = nanmax(adj_ssn);
end

% TAS Arithmetic mean based on cc and ss
tas_amean = 0.5*(adj_ssn/max_ssn + adj_cc_q75/max_cc);

% TAS Geometric mean based on cc and ss
tas_gmean = sqrt(clip(adj_ssn,0.001,inf).*clip(adj_cc_q75, 0.001, inf))/sqrt(max_ssn * max_cc);
%% Rank based TAS
ss_frank = rankorder(adj_ssn, 'fixties', true, 'direc','ascend','as_fraction',true);
cc_frank = rankorder(adj_cc_q75, 'fixties', true, 'direc','ascend','as_fraction',true);
% TAS rank based 
tas_rank = 0.5*(ss_frank+cc_frank);
%%
res = struct('tas_gmean', num2cell(tas_gmean),...
             'tas_amean', num2cell(tas_amean),...
             'tas_rank', num2cell(tas_rank));
end
