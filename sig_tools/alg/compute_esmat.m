function es = compute_esmat(ds, gset, varargin)

pnames = {'weight'};
dflts = {'classic'};
args = parse_args(pnames, dflts, varargin{:});

[nr, nc] = size(ds.mat);
% number of genesets
ng = length(gset);
esmat = nan(nc, ng);
set_size = zeros(length(gset), 1);
% rid_lut = list2dict(ds.rid);
rid_lut = mortar.containers.Dict(ds.rid);
for ii=1:ng
    tf = rid_lut.iskey(gset(ii).entry);
    %     ridx = cell2mat(rid_lut.values(gset(ii).entry));
    if nnz(tf)>0
        ridx = rid_lut(gset(ii).entry(tf));
        set_size(ii) = length(ridx);
        switch lower(args.weight)
            case 'weighted'
                [res, hitrank, hitind, esmax] = compute_es(ridx, ds.mat, [], 'weight', 'weighted', 'isranked', false);
            case 'classic'
                rnk = rankorder(ds.mat, 'direc', 'descend',...
                    'zeroindex','false', 'fixties', false);
                [res, hitrank, hitind, esmax] = compute_es(ridx, rnk, [], 'weight', 'weighted', 'isranked', true);
        end
        esmat(:, ii) = esmax;
    end
end

es = mkgctstruct(esmat, 'rid', ds.cid, 'rdesc', ds.cdesc, 'rhd', ds.chd,...
    'cid', {gset.head}', 'cdesc', [{gset.desc}',num2cell(set_size)], 'chd', {'desc','set_size'});
end