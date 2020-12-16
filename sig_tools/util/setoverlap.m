function ov_ds = setoverlap(varargin)
% SETOVERLAP determine pairwise overlaps between genesets.
% setoverlap(S1) returns the jaccard overlap of columns of of dataset S1
% setoverlap(S1, S2, ...) Computes jaccard overlaps of the collated columns
% of S1, S2,...
% setoverlap(S1, S2, ..., METRIC) Uses the specified overlap metric. The
% following metrics are supported: {'jaccard', 'overlapcoef', 'intersect'}

nin = nargin;
assert(nin>0, 'Insufficient arguments');

metric = 'jaccard';
% tf = strcmpi('intersect', varargin);
tf = strcmpi(varargin{end}, {'jaccard', 'overlapcoef', 'intersect'});
if any(tf)
    metric=varargin{end};
    varargin(end)=[];
    nin=nin-1;
end

s = parse_geneset(varargin{1});
for ii=2:nin
    s = [s; parse_geneset(varargin{ii})];
end

nset = length(s);

% all entries
memb = setunion(s);
lut = mortar.containers.Dict(memb);

nmemb = length(memb);
tf = zeros(nmemb, nset);
for ii=1:nset
    tf(lut(s(ii).entry), ii) = 1;
end

cid = {s.head}';

switch(metric)
    case 'jaccard'
        % ov = squareform(1-pdist(tf', 'jaccard'))+eye(nset);
        ov = fastjaccard(tf');
    case 'overlapcoef'
        ov = fastoverlapcoef(tf');
    case 'intersect'
        ov = fastintersect(tf');
end
ov_ds = mkgctstruct(ov, 'rid', cid, 'cid', cid);

end
