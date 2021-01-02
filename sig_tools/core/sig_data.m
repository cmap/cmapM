function info = sig_data(sig_id, varargin)
% SIG_INFO Get signature annotations from Mongo.
%   INFO = SIG_INFO(SIG_ID) Returns annotations for each signature id.
%   SIG_ID can be a string, cell array or a GRP file. INFO is a structure
%   with length(SIG_ID) rows.
%
%   Example:
%   sig_info('KDD009_PC3_96H:TRCN0000040081')
%
% TODO:
% Return annnotated dataset of signatures
    
pnames = {'mongo_location', 'mongo_info'};
dflts = {'cloud', fullfile(mortarconfig('mongo_config_path'),'mongo_servers.txt')};
args = parse_args(pnames, dflts, varargin{:});

if ischar(sig_id) && isfileexist(sig_id)
    sig_id = parse_grp(sig_id);
elseif ischar(sig_id)
    sig_id = {sig_id};
end
nsig = length(sig_id);

info = struct('sig_id', sig_id);
field = {'score'};
nf = length(field);
% infolut = list2dict(sig_id);

assert(iscell(sig_id), 'sig_id must be a cell array or grp file');

mdb = get_mongo_info(args.mongo_info, args.mongo_location);

MongoStart
m = Mongo(mdb.server_id);

assert(m.isConnected(), 'Could not connect to %s', mdb.server_id);

ok = m.authenticate(mdb.user_id, mdb.password, mdb.sig_db);
assert (ok, 'Unable to authenticate to db:%s', mdb.sig_db);
ns = sprintf('%s.sig_data', mdb.sig_db);

score = mkgctstruct(zeros(nfeature, nsig), 'cid', sig_id, 'cdesc'
for ii=1:nsig
    q = BsonBuffer();
    q.append('sig_id', sig_id{ii});
    cursor = MongoCursor(q.finish());
    m.find(ns, cursor);
    %run query
    if cursor.next()
        % document
        b = cursor.value;
        for jj=1:nf
            info(ii).(field{jj}) = b.value(field{jj});
        end
    else
        warn ('Query did not return any results');
    end    
end

% cursor = MongoCursor(query);

% % build query
% buf = BsonBuffer();
% buf.startArray('$in');
% for ii=1:nsig
%     buf.append(num2str(ii-1), sig_id{ii});
% end
% buf.finishObject();
% 
% q = BsonBuffer();
% q.append('sig_id', buf.finish());
% query = q.finish();
% 
% cursor = MongoCursor(query);
% 
% %run query
% if m.find(ns, cursor) 
%     while cursor.next() 
%         % document
%         b = cursor.value;                 
%         for ii=1:nf
%             info(infolut(b.value('sig_id'))).(field{ii}) = b.value(field{ii});
%         end        
%     end
% else
%     warn ('Query did not return any results');
% end

% MongoStop

end