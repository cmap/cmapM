function [esmax, es, rankmax, leadf] = fast_es_core(srt_rank, max_rank, isweighted, srt_wt)
% FAST_ES_CORE Optimized ES computation.
%
% [ESMAX, ES, RANKMAX, LF] FAST_ES_CORE(SRT_RANK, MAX_RANK, ISWEIGHTED,
% SRT_WT) returns the enrichment score ESMAX, the running enrichment score
% at each hit index ES, the RANK corresponding to ESMAX RANKMAX and the
% fraction of the geneset in the leading edge of each rank list LF.
% SRT_RANK is a sorted matrix of ranks [G x C], corresponding to G entries
% of a geneset and C columns of the rank matrix. MAX_RANK is the maximum
% possible rank in the rank matrix. ISWEIGHTED is false for unweighted ES.
% SRT_WT is the sorted matrix of weights [G x C] in the same order as
% SRT_RANK.

[G, C] = size(srt_rank);

if isempty(srt_rank)
    % handle empty lists
    esmax = zeros(1, max(C, 1));
    es = esmax;
    rankmax = esmax;
else    
    % Costs
    if ~isequal(G, max_rank)
        missCost = -1/(max_rank - G);
    else
        missCost = -1;
    end
    
    if isweighted
        abs_wt = abs(srt_wt);
        hitCost = bsxfun(@rdivide, abs_wt, sum(abs_wt, 1));
    else
        hitCost = 1/G;
    end
    
    delta = (diff([zeros(1, C); srt_rank], 1, 1) - 1)*missCost;
    
    % Running ES at hit indices
    es = cumsum(delta + hitCost, 1);
    
    % Running ES adjustment We need to keep track of running ES at the
    % trailing edge (i.e. before adding the hitCost) since it could exceed
    % the leading edge for negative scores.
    es_pre = es - hitCost;
    use_pre = abs(es) < abs(es_pre);
    es(use_pre) = es_pre(use_pre);
    
    % Maxima
    [~, ridx] = max(abs(es), [], 1);
    % Convert to linear index
    max_idx = ridx + (G*(0:C-1));
    
    % Maxima with sign
    esmax = es(max_idx);
    
    % rank at max ES
    rankmax = srt_rank(max_idx);
    
    % Leading fraction
    leadf = zeros(C, 1);
    pos_idx = esmax >= 0;
    leadf(pos_idx) = ridx(pos_idx);
    leadf(~pos_idx) = G - ridx(~pos_idx) + 1;
    leadf = leadf / G;
end

end