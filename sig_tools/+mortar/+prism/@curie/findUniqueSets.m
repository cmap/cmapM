function [uniq_gmt, set_rpt, ds_ov] = findUniqueSets(gmt, thresh, metric)

gmt = parse_geneset(gmt);
set_size = [gmt.len]';
nset = length(gmt);
ds_ov = setoverlap(gmt, metric);
has_overlap = ds_ov.mat >= thresh;

node_table = table(ds_ov.cid, set_size, 'VariableNames', {'Name', 'set_size'});
% construct un-directed graph
g = graph(has_overlap, node_table, 'upper', 'OmitSelfLoops');
% find connected components
set_group_idx = conncomp(g);
set_group_idx = set_group_idx(:);

% component sizes
set_group_size = accumarray(set_group_idx, ones(length(set_group_idx),1));

is_selected = true(nset, 1);
% multi-node components
graph_idx = find(set_group_size > 1);
is_graph_member = ismember(set_group_idx, graph_idx);
is_selected(is_graph_member) = false;
ncomp = length(graph_idx);
dbg(1, '%d components detected', ncomp)
%node_lut = mortar.containers.Dict(g.Nodes.Name);

% minimum graph size to run AP
N_FOR_AP = 10;
for ii=1:ncomp    
    this = set_group_idx == graph_idx(ii);
    subg = subgraph(g, this);        
    this_nodes = subg.Nodes.Name;
    nthis = nnz(this);
    % if subgraph is large use Affinity Propagation to pick exemplars
    if nthis > N_FOR_AP
        dbg(1, '%d/%d %d nodes, %d edges using AP', ii, ncomp, nnz(this), subg.numedges);
        this_sim = ds_slice(ds_ov, 'cid', this_nodes, 'rid', this_nodes);
        apidx = apcluster(this_sim.mat, median(this_sim.mat), 'maxits', 1000);
        pick_idx = findnode(g, this_nodes(unique(apidx)));
        dbg(1, 'Picked %d exemplars', length(pick_idx));
    else
        dbg(1, '%d/%d %d nodes, picking smallest node', ii, ncomp, nnz(this));
        
        minidx = min_index(subg.Nodes.set_size);
        pick_idx = findnode(g, this_nodes(minidx));
    end
    is_selected(pick_idx) = true;
end

uniq_gmt = gmt(is_selected);
set_rpt = struct('set_id', g.Nodes.Name,...
    'set_size', num2cell(g.Nodes.set_size),...
    'set_group', num2cell(set_group_idx),...
    'group_size', num2cell(set_group_size(set_group_idx)),...
    'is_selected_set', num2cell(is_selected));
end