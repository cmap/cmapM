function S = mongo_query(query, varargin)
% MONGO_QUERY Query the mongo annotations and return a structure array with results
%   S = MONGO_QUERY(QUERY, VARARGIN)
%   QUERY is a cell array specifying the mongo query to be made
%       each row of the cell array specifies a different field
%       the first column gives the field, the second column gives the query condition
%       in the case of complex conditions, the second column is itself a cell array

% read the arguments
pnames = {'fields', 'mongo_location', 'mongo_info'};
dflts = { {'pert_id', 'pert_desc', 'cell_id',...
          'pert_type', 'pert_time', 'pert_time_unit',...
          'pert_dose', 'pert_dose_unit', 'is_gold',...
          'distil_cc_q75','distil_ss','pct_self_rank_q25'}, ...
        'local', fullfile(mortarconfig('mongo_config_path'),'mongo_servers.txt') };
args = parse_args(pnames, dflts, varargin{:});
nfields = length(args.fields);

% connect to Mongo
mdb = get_mongo_info(args.mongo_info, args.mongo_location);
MongoStart
m = Mongo(mdb.server_id);
assert(m.isConnected(), 'Could not connect to %s', mdb.server_id);
ok = m.authenticate(mdb.user_id, mdb.password, mdb.sig_db);
assert (ok, 'Unable to authenticate to db:%s', mdb.sig_db);
ns = sprintf('%s.%s', mdb.sig_db, mdb.sig_collection);

% build the query and get the number of matches
ncond = size(query, 1);
q = BsonBuffer();
for ii = 1:ncond
    q.append(query{ii,1}, query{ii,2});
end
q_finished = q.finish();
% preallocate structure array, as long as entries were returned
n_entries = m.count(ns, q_finished);
if ~n_entries
    error('No documents match the query')
end
S(n_entries,1) = struct();
cursor = MongoCursor(q_finished);
m.find(ns, cursor);
for ii = 1:n_entries
    disp(ii)
    cursor.next();
    for jj = 1:nfields
        f = args.fields{jj};
%         foo = cursor.value.find(f).value;
        b = cursor.value;
%         i=BsonIterator; 
%         calllib('MongoMatlabDriver', 'mongo_bson_find', b.h, f, i.h);
        foo = 0;
    end
end
        

