function [full_tbl, comm_tbl] = parse_cos(infile, mapfile)
% Parse output file of the community finding program : COS

% See: http://sourceforge.net/p/cosparallel/wiki/UserGuide/

% read map
fid = fopen(mapfile, 'rt');
v = textscan(fid,'%s %s');
% node index to label
lut = mortar.containers.Dict(v{2}, v{1});
fclose(fid);

fid = fopen(infile, 'rt');
% read in all lines
raw = textscan(fid, '%s', 'delimiter', ' ');
fclose(fid);

if ~isempty(raw)
    raw = raw{1};
    % find beginning of each list
    isbeg = rematch(raw, ':');
    
    tok = tokenize(raw(isbeg),':');
    % first node id
    raw(isbeg) = cellfun(@(x) x{2}, tok, 'uniformoutput', false);
    node_id = str2double(raw);
    node_label = lut(raw);
    
    % community id [0, k-1]
    comm_id_label = cellfun(@(x) x{1}, tok, 'uniformoutput', false);
    nr = length(raw);
    comm_id = zeros(nr, 1);
    comm_id(isbeg) = 1;
    idx = cumsum(comm_id);
    comm_id = comm_id_label(idx);
    
    full_tbl = struct('node_id', raw,...
                      'node_label', node_label,...
                      'community_id', comm_id,...
                      'clique_id', num2cell(idx));
    
end

% community report with stats

[cn, nl] = getcls(comm_id);
ncomm = length(cn);
comm_tbl  = struct('community_id', cn,...
                   'sz', 0,...
                   'node_label', '',...
                   'node_deg', '');
for ii=1:ncomm
    keep = nl==ii;
    [uniq_node, node_num] = getcls(node_label(keep));
    node_deg = accumarray(node_num, ones(size(node_num)));
    [sort_deg, sort_ord] = sort(node_deg, 'descend');
    
    comm_tbl(ii).sz = length(uniq_node);
    comm_tbl(ii).node_label = uniq_node(sort_ord);
    comm_tbl(ii).node_deg = sort_deg;
end
               
               

end