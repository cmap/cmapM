function [ds, idx] = hclust(ds, varargin)
% HCLUST Apply hierarchical clustering to a dataset.
% HC = HCLUST(DS) applies hierarchical clustering to columns of DS (a GCT
% structure or file). It computes pairwise distances between columns on DS
% using spearman distance followed by hierarchical clustering of columns.
% Returns HC which is the same as DS with the columns ordered based on the
% leaf ordering obtained by clustering.
%
% HC = HCLUST(DS, param1, value1,...) Specify optional arguments:
%   'metric'  string, metric used for computing distances. See PDIST for 
%             valid options. Default is 'spearman'
%   'linkage' string, algorithm to use to construct the hierarchical 
%             cluster tree. See LINKAGE for valid options. Default is 
%             'complete'
%   'cluster_row' logical, Cluster rows of the dataset if true. Default is false
%   'cluster_column' logical, Cluster columns of the dataset if true. 
%                    Default is true
%   'make_symmetric' logical, if DS is square, reorders the rows and
%                    columns identically. Default is false
%   'is_pairwise' logical, Skips computing pairwise distances and uses DS 
%                 as a distance or similarity matrix. Default is false

opt = struct('name', {'--metric', '--linkage', '--cluster_row',...
    '--cluster_column', '--make_symmetric', '--is_pairwise'},...
    'default', {'spearman', 'complete', false,...
    true, true, false});
p = mortar.common.ArgParse(mfilename);
p.add(opt);
args = p.parse(varargin{:});
if args.is_pairwise
    clusterfn = @cluster_1d_pw;
else
    clusterfn = @cluster_1d;
end

ds = parse_gctx(ds);
[nr, nc]=size(ds.mat);
if args.cluster_row
    idx = clusterfn(ds.mat, args.metric, args.linkage);
    ds = ds_slice(ds, 'ridx', idx);
    if args.make_symmetric && isequal(nr, nc)
        ds = ds_slice(ds, 'cidx', idx);
    end
end

if args.cluster_column
    idx = clusterfn(ds.mat', args.metric, args.linkage);
    ds = ds_slice(ds, 'cidx', idx);
    if args.make_symmetric && isequal(nr, nc)
        ds = ds_slice(ds, 'ridx', idx);
    end

end

end

function leaford = cluster_1d_pw(x, ~, link_method)
% order provided pairwise similarity or distance matrix
% is the diagonal 1 (similarity) or 0 (distance)?
is_similarity = all(abs(diag(x)-1)<1e-4);
if is_similarity
    dbg(1, 'Similarity matrix detected: Transforming to distances')
    x = 1-x;
else
    dbg(1, 'Distance matrix detected')    
end
d = tri2vec(x, 1, false)';
tree = linkage(d, link_method);
leaford = optimalleaforder(tree, d);
end

function leaford = cluster_1d(x, metric, link_method)
% cluster the matrix and return the optimal leaf ordering
d = pdist(x, metric);
tree = linkage(d, link_method);
leaford = optimalleaforder(tree, d);
end