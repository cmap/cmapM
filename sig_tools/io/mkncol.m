function mkncol(ofname, ds, varargin)
% MKNCOL Save edgelist in a graph in the NCOL format.
%
% MKNCOL(OFNAME, DS) Saves unweighted graph as OFNAME. DS is GCT structure
% of an NxN adjacency matrix (non-zero values are considered edges). Common
% annotations of the rows and columns are also saved.
%
% MKNCOL(OFNAME, DS, NAME1, VAL1,...) 
%   'isweighted': Saves a weighted graph if true. Default is false.
%   'isdirected': Saved a directed graph if true. Default is false.
%
% See: http://igraph.sourceforge.net/doc/R/read.graph.html

opt = struct('name', {'--isweighted', '--isdirected'},...
        'default', {false, false});
parser = mortar.common.ArgParse(mfilename);
parser.add(opt);
args = parser.parse(varargin{:});

fid = fopen(ofname, 'wt');

% edges
if args.isdirected
    x = ds.mat;
    x(1:size(ds.mat,1)+1:numel(ds.mat)) = 0;
    [ir, ic] = find(x);
else
    [ir, ic] = find(triu(ds.mat, 1));
end

if args.isweighted        
    edges = [ds.rid(ir), ds.cid(ic), num2cell(ds.mat(ic,ir))]';
    fprintf(fid, '%s %s %g\n', edges{:});
else    
    edges = [ds.rid(ir), ds.cid(ic)]';
    fprintf(fid, '%s %s\n', edges{:});
end

fclose(fid);

end