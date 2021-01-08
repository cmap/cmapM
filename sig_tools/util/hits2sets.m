function [rpt, phits, nhits] = hits2sets(hits)
% HITS2SETS Get identifiers from a ternary matrix 
%
% [RPT, PHITS, NHITS] = HITS2SETS(HITS) Computes sets of column ids for
% each row in HITS, where HITS is a GCT ternary matrix with the following
% elements {-1, 0, 1}.
%
% RPT is structure with the same dimension and row-prder as HITS and the
% following fields:
%   'rid' : row identifiers of HITS
%   'desc' : pert_id for rows in HITS
%   'pos_hit' : cell array of positive hits
%   'neg_hit' : cell array of negative hits
%
% PHITS and NHITS are sets of positive and negative hits respectively

% positive connections
[pir, pic] = find(hits.mat>0);
% negative connections
[nir, nic] = find(hits.mat<0);
if ~isempty(hits.rhd) && isKey(hits.rhd, 'pert_id')
    desc = ds_get_meta(hits, 'row', 'pert_id');
else
    empty = {'-666'};
    desc = empty(ones(size(hits.mat, 1),1));    
end
ptbl = struct('group_id', hits.rid(pir), 'member_id', hits.cid(pic), 'desc', desc(pir));
ntbl = struct('group_id', hits.rid(nir), 'member_id', hits.cid(nic), 'desc', desc(nir));

rpt = struct('rid', hits.rid, 'desc', desc,...
             'pos_hit', '-666', 'neg_hit', '-666',...
             'npos', 0, 'nneg', 0, 'ntot', 0);
rdict = mortar.containers.Dict(hits.rid);

if ~isempty(ptbl)
    phits = tbl2gmt(ptbl); 
    pv = {phits.entry}';
    npos = {phits.len}';
    [rpt(rdict({phits.head})).pos_hit] = pv{:};
    [rpt(rdict({phits.head})).npos] = npos{:};
else

    phits = [];
end
if ~isempty(ntbl)
    nhits = tbl2gmt(ntbl); 
    nv = {nhits.entry}';
    nneg = {nhits.len}';
    [rpt(rdict({nhits.head})).neg_hit] = nv{:};
    [rpt(rdict({nhits.head})).nneg] = nneg{:};
else
    nhits = [];
end
if ~isempty(phits) && ~isempty(nhits)
    ntot = num2cell([rpt.npos]+[rpt.nneg]);
elseif ~isempty(phits)
    ntot = num2cell([rpt.npos]);
elseif ~isempty(nhits)
    ntot = num2cell([rpt.nneg]);
else
    ntot = num2cell(zeros(length(rpt),1));
end
[rpt.ntot] = ntot{:};

end

