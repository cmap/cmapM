function res =  computeCmapScore(uptag, dntag,...
                                 ds_rank, isweighted,...
                                 ds_score, es_tail,...
                                 max_rank)
% computeCmapScore Compute CMap Enrichment statistic 
% RES = computeCmapScore(UP, DN,...
%                        DS_RANK, ISWEIGHTED,...
%                        DS_SCORE, ES_TAIL, MAX_RANK)
%
% Returns a structure RES with the following fields:
%   'cs' : Combined connectivity scores. GCT struct with dimensions [C x Q]
%   'cs_up' : Connectivity scores corresponding to the UP set. Dimensions [C x Q]
%   'cs_dn' : Connectivity score corresponding to the DN set. Dimensions [C x Q]
%   'leadf_up' : Leading edge fraction for the UP set. Dimensions [C x Q]
%   'leadf_dn' : Leading edge fraction for the DN set. Dimension [C x Q]
%

import mortar.compute.Connectivity

% load data
[uptag, dntag, ds_rank,...
 ds_score, max_rank, query_id,...
 upind, dnind] = loadData(uptag, dntag, ds_rank,...
                          ds_score, isweighted, es_tail,...
                          max_rank);

% Compute CMAP enrichment statistic
[score, leadf] = Connectivity.cmapScoreCore(upind, dnind,...
                                            ds_rank, max_rank,...
                                            isweighted, ds_score,...
                                            es_tail);
% sets that were used
res.uptag = uptag;
res.dntag = dntag;

% combined score                
res.cs = mkgctstruct(score(:,:,3), 'rid', ds_rank.cid,...
                     'rhd', ds_rank.chd, 'rdesc', ds_rank.cdesc,...
                     'cid', query_id);
% up score                 
res.cs_up = mkgctstruct(score(:,:,1), 'rid', ds_rank.cid,...
                     'rhd', ds_rank.chd, 'rdesc', ds_rank.cdesc,...
                     'cid', query_id);

% down score
res.cs_dn = mkgctstruct(score(:,:,2), 'rid', ds_rank.cid,...
                     'rhd', ds_rank.chd, 'rdesc', ds_rank.cdesc,...
                     'cid', query_id);

%leading fraction up
res.leadf_up = mkgctstruct(leadf(:,:,1), 'rid', ds_rank.cid,...
                     'rhd', ds_rank.chd, 'rdesc', ds_rank.cdesc,...
                     'cid', query_id);
                 
% leading fraction down
res.leadf_dn = mkgctstruct(leadf(:,:,2), 'rid', ds_rank.cid,...
                     'rhd', ds_rank.chd, 'rdesc', ds_rank.cdesc,...
                     'cid', query_id);
                
end

function [uptag, dntag] = loadGeneset(uptag, dntag, es_tail)
% Load data needed for running a query
switch es_tail
    case 'both'
        if mortar.util.File.isfile(uptag, 'file')
            uptag = parse_geneset(uptag);
        elseif ischar(uptag)
            error('UP geneset not found');
        end
        if mortar.util.File.isfile(dntag, 'file')
            dntag = parse_geneset(dntag);
        elseif ischar(dntag)
            error('DN geneset not found');
        end
    case 'up'
        if mortar.util.File.isfile(uptag, 'file')
            uptag = parse_geneset(uptag);
        elseif ischar(uptag)
            error('UP geneset not found');
        end
    case 'down'
        if mortar.util.File.isfile(dntag, 'file')
            dntag = parse_geneset(dntag);
        elseif ischar(dntag)
            error('DN geneset not found');
        end
    otherwise
        error('Invalid es_tail specified : %s', es_tail);
end
end

function [uptag, dntag, ds_rank,...
          ds_score, max_rank, query_id,...
          upind, dnind] = loadData(uptag,...
                                  dntag,...
                                  ds_rank,...
                                  ds_score,...
                                  isweighted,...
                                  es_tail,...
                                  max_rank)

% read genesets
[uptag, dntag] = loadGeneset(uptag, dntag, es_tail);

if isds(ds_rank)
    rid_dict = mortar.containers.Dict(ds_rank.rid);
    assert(~isempty(max_rank) && max_rank>0, 'Max rank not valid');    
elseif mortar.util.File.isfile(ds_rank, 'file')
    ds_annot = parse_gctx(ds_rank, 'annot_only', true);
    rid_dict = mortar.containers.Dict(ds_annot.rid);
    max_rank = length(ds_annot.rid);
elseif ischar(ds_rank)
    error('Rank file not found');
end

% validate and a filter spurious features
[uptag, dntag] = mortar.compute.Connectivity.checkGenesets(uptag, dntag, rid_dict, es_tail);

% full feature space
alltag = setunion([uptag; dntag]);

% load rank and score matrices
ds_rank = parse_gctx(ds_rank, 'rid', alltag);
if isweighted
    ds_score = parse_gctx(ds_score, 'rid', alltag);
else
    ds_score = [];
end

% lookup row indices for each geneset
[upind, dnind, query_id] = computeGeneIndices(uptag, dntag, es_tail,...
                                              mortar.containers.Dict(alltag));


end

function [upind, dnind, query_id] = computeGeneIndices(uptag, dntag, es_tail, rid_dict)
% Get row indices into the rank (score) matrix for each geneset

switch(lower(es_tail))
    case 'both'
        upind = tag2idx({uptag.entry}, rid_dict);
        dnind = tag2idx({dntag.entry}, rid_dict);
        query_id = regexprep(upper({uptag.head}'), '_UP$', '');
    case 'up'
        upind = tag2idx({uptag.entry}, rid_dict);
        dnind = {};
        query_id = regexprep(upper({uptag.head}'), '_UP$', '');
    case 'down'
        upind = {};
        dnind = tag2idx({dntag.entry}, rid_dict);        
        query_id = regexprep(upper({dntag.head}'), '_DN$', '');
end
end

function idx = tag2idx(tags, dict)
% Lookup indices for tags
% note this seems much faster than a cellfun lookup at least for nt>1000
nt = length(tags);
idx = cell(nt, 1);
for ii=1:nt
    idx{ii} = cell2mat(dict.values(tags{ii}));
end
end