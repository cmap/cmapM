function [up, dn] = webquery_genesets(query_id, varargin)
%read genesets from webapp query 

pnames = {'mongo_location', 'mongo_info'};
dflts = {'webapp', fullfile(mortarconfig('mongo_config_path'),'mongo_servers.txt')};
args = parse_args(pnames, dflts, varargin{:});

if ischar(query_id) && isfileexist(query_id)
    query_id = parse_grp(query_id);
elseif ischar(query_id)
    query_id = {query_id};
end
nsig = length(query_id);

up = struct('head', query_id, 'desc', '', 'len', [], 'entry', []);
dn = struct('head', query_id, 'desc', '', 'len', [], 'entry', []);

mdb = get_mongo_info(args.mongo_info, args.mongo_location);

MongoStart
m = Mongo(mdb.server_id);
assert(m.isConnected(), 'Could not connect to %s', mdb.server_id);
ok = m.authenticate(mdb.user_id, mdb.password, mdb.sig_db);
assert (ok, 'Unable to authenticate to db:%s', mdb.sig_db);
ns = sprintf('%s.%s', mdb.sig_db, mdb.sig_collection);

for ii=1:nsig
    q = BsonBuffer();
    q.append('_id', BsonOID(query_id{ii}));
    cursor = MongoCursor(q.finish());
    m.find(ns, cursor);
    if cursor.next()
        % document
        b = cursor.value;
        up(ii).entry = b.value('upTags');
        desc = b.value('queryName');
        up(ii).len = length(up(ii).entry);
        up(ii).desc = desc;
        
        dn(ii).entry = b.value('dnTags');
        dn(ii).len = length(dn(ii).entry);
        dn(ii).desc = desc;
    else
        error('Query did not return any results');
    end
end

end