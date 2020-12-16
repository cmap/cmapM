function [esmax,es, rankmax, leadf] = fastWTCSCore(srt_rank, max_rank, srt_wt)
% fastESCore Optimized enrichment score computation.
%
% [ESMAX, ES, RANKMAX, LF] = fastESCore(SRT_RANK, MAX_RANK, ISWEIGHTED, SRT_WT) 
% returns the enrichment score ESMAX, the running enrichment score
% at each hit index ES, the RANK corresponding to ESMAX RANKMAX and the
% fraction of the geneset in the leading edge of each rank list LF.
% SRT_RANK is a sorted matrix of ranks [G x C], corresponding to G entries
% of a geneset and C columns of the rank matrix. MAX_RANK is the maximum
% possible rank in the rank matrix. ISWEIGHTED is false for unweighted ES.
% SRT_WT is the sorted matrix of weights [G x C] in the same order as
% SRT_RANK.
%
% Adapted by: Anup Jonchhe
%
% This code solves for wtcs of a single query, but for all signatures.
% Contestant code solves for wtcs of all queries, for one signature.
%
%

[G, C] = size(srt_rank);
esmax = zeros(1,C);
%ssum_tab = zeros(1,C); %sum of all hits 
rss = zeros(1,C); %running sum tracker
rss_tab = zeros(2*G,C); %tracks running sum, both leading and trailing
leadf = zeros(1,C);

ssum_tab = sum(srt_wt);   

ssum_tab = (max_rank - G)./ssum_tab; %(M-N)/s_total

plusone = ones(1,C);


for g = 1:G
    %Is score max dev negative between hits
    m_abs = abs(esmax);
    tmp = rss - srt_rank(g,:);
    tmp_abs = abs(tmp);
    cmpres = (tmp_abs > m_abs);
    esmax(cmpres) = tmp(cmpres);
    rss_tab((2*g-1),:) = tmp;

    %Add hit increment
    tmp2 = srt_wt(g,:) .* ssum_tab;
    rss = rss + tmp2;
    tmp = tmp + tmp2;
    tmp_abs = abs(tmp);
    m_abs = abs(esmax);
    cmpres = (tmp_abs > m_abs);
    esmax(cmpres) = tmp(cmpres);
    rss_tab((2*g),:) = tmp;
    rss = rss + plusone;
    
    [row,~] = find(esmax == rss_tab);
    rankmax = ceil(row./2);
end
esmax = exmax./(max_rank - G);
es = rss_tab./(max_rank - G);

pos = esmax >=0;
leadf(pos) = rankmax(pos)./G;
leadf(~pos) = (G-rankmax(~pos)+1)./G;
end