function [score, leadf] = cmap_score_core(upind, dnind, ds_rank, ...
                              max_rank, isweighted, ds_score, es_tail)
% CMAP_SCORE_CORE Core implementation of the CMAP score computation.
%   [SCORE, LEADF] = CMAP_SCORE_CORE(UPIND, DNIND, DS_RANK, MAX_RANK,
%                                    ISWEIGHTED, DS_SCORE. ES_TAIL)
%   Inputs:
%   UPIND and DNIND : cell arrays of row indices of DS_RANK. Each pair of
%       entries in UPIND and DNIND represent a query. Both UPIND and DNIND
%       should have the same length Q and should be in the same order.
%   DS_RANK : a GCT dataset structure of one-based ranks. 
%   MAX_RANK : maximum possible rank in the rank matrix
%   ISWEIGHTED : computes weighted score if true
%   DS_SCORE : a GCT dataset structure of weights to apply for a weighted
%       score. The dimensions and order of row and columns should match
%       DS_RANK.
%   ES_TAIL : Specify two-tailed or one-tailed statistic. Can be {both, up,
%   down}
%   Outputs:
%   SCORE : a 3-d matrix of dimensions (C x Q x 3) where C is the number of
%       columns in DS_RANK. The 3rd dimension represents UP, DOWN and
%       connectivity scores respectively
%   LEADF : a 3-d matrix of dimensions (C x Q x 2) . The 3rd dimension
%   represents the leading edge fraction for the UP and DN components of
%   the query respectively.

warning('DEPRECATED! Use mortar.compute.Connectivity.cmapScoreCore instead');

[numFeatures, numSamples] = size(ds_rank.mat);

switch (lower(es_tail))
    case 'up'
        nq = length(upind);
        assert(iscell(upind));
    case 'down'
        nq = length(dnind);
        assert(iscell(dnind));
    case 'both'
        nq = length(upind);
        assert(iscell(upind));
        assert(iscell(dnind));
        assert(isequal(nq, length(dnind)));
    otherwise
        error('Invalid es_tail, expected {up, down, both} got :%s', es_tail);
end

score = zeros(numSamples, nq, 3);
leadf = zeros(numSamples, nq, 2);
for ii=1:nq
    switch (lower(es_tail))
        case 'both'
            [srt_up, srtidx_up] = sort(ds_rank.mat(upind{ii}, :), 1);
            [srt_dn, srtidx_dn] = sort(ds_rank.mat(dnind{ii}, :), 1);
            
            if isweighted
                [up_esmax, ~, ~, up_leadf] = fast_es_core(srt_up, max_rank, true,...
                    ds_score.mat(bsxfun(@plus, upind{ii}(srtidx_up), numFeatures*(0:numSamples-1))));
                [dn_esmax, ~, ~, dn_leadf] = fast_es_core(srt_dn, max_rank, true,...
                    ds_score.mat(bsxfun(@plus, dnind{ii}(srtidx_dn), numFeatures*(0:numSamples-1))));
            else
                [up_esmax, ~, ~, up_leadf] = fast_es_core(srt_up, max_rank, false, []);
                [dn_esmax, ~, ~, dn_leadf] = fast_es_core(srt_dn, max_rank, false, []);
            end
            
            score(:, ii, 1) = up_esmax;
            score(:, ii, 2) = dn_esmax;
            
            % leading edge fraction
            leadf(:, ii, 1) = up_leadf;
            leadf(:, ii, 2) = dn_leadf;
            
            % Compute combined score
            score(:, ii, 3) = getcombinedes(up_esmax, dn_esmax, false);
        case 'up'
            [srt_up, srtidx_up] = sort(ds_rank.mat(upind{ii}, :), 1);            
            
            if isweighted
                [up_esmax, ~, ~, up_leadf] = fast_es_core(srt_up, max_rank, true,...
                    ds_score.mat(bsxfun(@plus, upind{ii}(srtidx_up), numFeatures*(0:numSamples-1))));
            else
                [up_esmax, ~, ~, up_leadf] = fast_es_core(srt_up, max_rank, false, []);
            end
            
            score(:, ii, 1) = up_esmax;
            
            % leading edge fraction
            leadf(:, ii, 1) = up_leadf;
            
            % Compute combined score
            score(:, ii, 3) = up_esmax;
        case 'down'
            [srt_dn, srtidx_dn] = sort(ds_rank.mat(dnind{ii}, :), 1);
            
            if isweighted
                [dn_esmax, ~, ~, dn_leadf] = fast_es_core(srt_dn, max_rank, true,...
                    ds_score.mat(bsxfun(@plus, dnind{ii}(srtidx_dn), numFeatures*(0:numSamples-1))));
            else
                [dn_esmax, ~, ~, dn_leadf] = fast_es_core(srt_dn, max_rank, false, []);
            end
            % negate scores to conform to the convention of getting
            % positive scores if the down-set is negatively enriched            
            score(:, ii, 2) = -dn_esmax;
            
            % leading edge fraction
            leadf(:, ii, 2) = dn_leadf;
            
            % Compute combined score
            score(:, ii, 3) = dn_esmax;
 
    end
end

end