function ov_ds = setoverlap2(varargin)
% SETOVERLAP determine pairwise overlaps between genesets.
% setoverlap(S1) returns the jaccard overlap of columns of of dataset S1
% setoverlap(S1, S2, ...) Computes jaccard overlaps of the collated columns
% of S1, S2,...
% setoverlap(S1, S2, ..., METRIC) Uses the specified overlap metric. The
% following metrics are supported: {'jaccard', 'overlapcoef', 'intersect'}

nin = nargin;
assert(nin>0, 'Insufficient arguments');

pnames = {'fnames', 'dbg_flag', 'metric'};
pnames_tmp = {'dbg_flag', 'metric'};
dflts = {[], 1, 'jaccard'};
args = parse_args(pnames, dflts, varargin{:});

out = varargin;
out(cellfun(@isnumeric, out)) = {num2str(cell2mat(out(cellfun(@isnumeric, out))))};
out(cellfun(@isstruct, out)) = {'XYZ'};
out(cellfun(@iscell, out)) = {'XYZ'};

if logical(sum(ismember(out,'dbg_flag'))) || logical(sum(ismember(out,'metric')))
    to_remove = [];
    
    to_remove_tmp = find(ismember(out, pnames_tmp)==1);
    if sum(to_remove_tmp)>0
        to_remove = [to_remove_tmp, to_remove_tmp+1];
    end

    count_to_remove = length(to_remove);
    if count_to_remove > 0
        varargin(to_remove) = [];
    end
    tf = strcmpi(args.metric, {'jaccard', 'overlapcoef', 'intersect'});
    if any(tf)
        metric=args.metric;
        dbg_flag = args.dbg_flag;
        nin=nin-count_to_remove;
        dbg(dbg_flag, 'metric:%s', metric);
    end
else
    % To be able to use legacy syntax, e.g.: setoverlap(structure, 'jaccard')
    metric = 'jaccard';
    tf = strcmpi(varargin{end}, {'jaccard', 'overlapcoef', 'intersect'});
    if any(tf)
        metric=varargin{end};
        varargin(end)=[];
        nin=nin-1;
    end
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
