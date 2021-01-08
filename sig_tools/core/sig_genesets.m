function [up, dn] = sig_genesets(sig_id, tag_type, varargin)

pnames = {'es_tail'};
dflts = {'both'};
args = parse_args(pnames, dflts, varargin{:});

if ischar(sig_id) && isfileexist(sig_id)
    sig_id = parse_grp(sig_id);
elseif ischar(sig_id)
    sig_id = {sig_id};
end
% nsig = length(sig_id);
% up = struct('head', sig_id, 'desc', '', 'len', [], 'entry', []);
% dn = struct('head', sig_id, 'desc', '', 'len', [], 'entry', []);

up_tag = sprintf('up%s', tag_type);
dn_tag = sprintf('dn%s', tag_type);

switch(lower(args.es_tail))
    case 'both'
        sinfo = sig_info(sig_id, 'fields', {'sig_id', 'pert_iname', up_tag, dn_tag});
        up = mkset(sinfo, 'sig_id', 'pert_iname', up_tag);
        dn = mkset(sinfo, 'sig_id', 'pert_iname', dn_tag);
        
    case 'up'
        sinfo = sig_info(sig_id, 'fields', {'sig_id', 'pert_iname', up_tag});
        up = mkset(sinfo, 'sig_id', 'pert_iname', up_tag);
        dn = struct([]);
        
    case 'down'
        sinfo = sig_info(sig_id, 'fields', {'sig_id', 'pert_iname', dn_tag});
        up = struct([]);
        dn = mkset(sinfo, 'sig_id', 'pert_iname', dn_tag);
    otherwise
        error('Invalid es_tail, expected {both, up, down} got: %s', args.es_tail);
        
end

% mdb = get_mongo_info(args.mongo_info, args.mongo_location);
% 
% m = mortar.containers.Mongo(mdb.server_id);
% assert(isequal(m.getDB(mdb.sig_db, mdb.user_id, mdb.password), 1),...
%     'Unable to open mongo db: %s', mdb.sig_db);
% assert(isequal(m.getCollection(mdb.sig_collection), 1),...
%     'Unable to open collection: %s', mdb.sig_collection);
% 
% up_tag = sprintf('up%s', tag_type);
% dn_tag = sprintf('dn%s', tag_type);
% q = m.findFromList('sig_id', sig_id,...
%         {'sig_id', 'pert_iname', up_tag, dn_tag});
% if ~isequal(q.size, nsig)
%     error('Some sig_ids not found in mongo');
% end
% 
% lut = list2dict(sig_id);
% while q.hasNext    
%     d = q.next;
%     idx = lut(d.get('sig_id'));
%     desc = d.get('pert_iname');
%     %up tags
%     up(idx).entry = cell(d.get(up_tag).toArray);
%     up(idx).desc = desc;
%     up(idx).len = length(up(idx).entry);
%     
%     %down tags
%     dn(idx).entry = cell(d.get(dn_tag).toArray);
%     dn(idx).desc = desc;
%     dn(idx).len = length(dn(idx).entry);
% end

end

function si = mkset(sinfo, head_id, desc_id, entry_id)
% Create geneset 
si = sinfo;
si = mvfield(si, head_id, 'head');
si = mvfield(si, desc_id, 'desc');
si = mvfield(si, entry_id, 'entry');
si = rmfield(si, setdiff(fieldnames(si), {'head', 'desc', 'entry'}));
len = num2cell(cellfun(@length, {si.entry}));
[si.len] = len{:};

end
