function [ps, ns] = scoreToPercentile(ns, ns2ps, dim, varargin)
% scoreToPercentile Convert normalized connectivity scores to percentile
% scores using a score to percentile score lookup table.
% rp = scoreToPercentile(ns, ns2ps, varargin)
% See also scoreToRankTransform

% minimum and maximum score range
minval=-4;
maxval=4;

[dim_str, dim_val] = get_dim2d(dim);
% operating dim
op_dim = 3 - dim_val;

vq = ds_get_meta(ns2ps, 'column', 'bin_center');
if isequal(dim_str, 'column')
    id_dim = 'rid';
    xid = intersect(ns.rid, ns2ps.rid, 'stable');
    assert(~isempty(xid), 'No common rids found');
    dbg(1, '%d common rids found', numel(xid)); 
else
    id_dim = 'cid';
    xid = intersect(ns.cid, ns2ps.rid, 'stable');
    assert(~isempty(xid), 'No common cids found');
    dbg(1, '%d common cids found', numel(xid)); 
end

% ensure that matrices are ordered identically
ns = ds_slice(ns, id_dim, xid);
ns2ps = ds_slice(ns2ps, 'rid', xid);
nsig = length(ns2ps.rid);

% percentile scores
ps = ns;

% transform normalized scores to percentiles
switch(dim_str)
    case 'row'
        for ii=1:nsig
            rq = ns2ps.mat(ii, :);
            ps.mat(:, ii) = interp1(vq, rq, clip(ns.mat(:, ii),...
                                minval, maxval), 'linear');
        end
    case 'column'
        for ii=1:nsig
            rq = ns2ps.mat(ii, :);
            ps.mat(ii, :) = interp1(vq, rq, clip(ns.mat(ii, :),...
                                minval, maxval), 'linear');
        end
    otherwise
        error('Unkown dimension %s', dim_str)
end

end
