function [info, keys] = mongo_info(mongo_collection, q, varargin)
% MONGO_INFO Get annotations from Mongo.
%   INFO = MONGO_INFO(COLLECTION, QUERY) Returns annotations from the Mongo
%   Collection COLLECTION for specified query QUERY. QUERY can be a string,
%   cell array or a GRP file. INFO is a structure annotations.
%
%   Examples: 
%   % query the pert_info collection
%   mongo_info('pert_info', {'BRD-A19037878', 'BRD-K70401845'})
%   mongo_info('sig_info', 'ASG001_MCF7_6H:BRD-A19037878-001-04-9:10')
%   mongo_info('sig_info','{sig_id:"ASG001_MCF7_6H:BRD-A19037878-001-04-9:10"}')

defaults_file = mapdir(fullfile(mortarconfig('mongo_config_path'),'default_fields.gmt'));
default = get_collection_defaults(mongo_collection, defaults_file);

pnames = {'fields', 'mongo_location',...
          'mongo_info',...
          'query_field', 'max_list_size', 'as_cell'};
dflts = {default.fields, 'current',...
         mapdir(fullfile(mortarconfig('mongo_config_path'),'mongo_servers.txt')),...
         default.query_field, 50000, false};

args = parse_args(pnames, dflts, varargin{:});
assert(~isempty(args.query_field), 'Query field must be specified');
isjson = false;
if ischar(q) && isfileexist(q)
    q = parse_grp(q);
elseif ischar(q) && q(1)=='{'
    %json input
    query = parse_json_string(q);
    isjson = true;
elseif ischar(q)
    q = {q};
elseif ~iscell(q)
    error('Invalid pert_id')
end

mdb = get_mongo_info(args.mongo_info, args.mongo_location);
m = mortar.containers.Mongo(tokenize(mdb.replica_set, ',', true));

%assert(m.isConnected(), 'Could not connect to %s', mdb.server_id);
ok = m.getDB(mdb.sig_db, mdb.user_id, mdb.password);
assert (ok, 'Unable to authenticate to db:%s', mdb.sig_db);
%ns = sprintf('%s.%s', mdb.sig_db, mdb.sig_collection);
m.getCollection(mongo_collection);

if ~isjson
    % Q needs to be unique
    [uniq, iq, iuq] = unique(q, 'stable');
    if ~isequal(length(iq), length(iuq))
        oldq = q;
        q = uniq;
        has_dup = true;
    else
        has_dup = false;
    end
    
    nsig = length(q);
    
    assert(iscell(q), 'Q must be a cell array or grp file');
    assert(iscell(args.fields), 'fields must be a cell array');
    
    nchunk = ceil(nsig / args.max_list_size);
%     sig_dict = mortar.containers.Dict(q);

    sig_dict = list2dict(q);
    keys = args.fields;
    % for sub doc queries just keep the parent
    out_keys = unique(regexprep(keys, '\..*', ''), 'stable');
%     field_dict = mortar.containers.Dict(out_keys);
    field_dict = list2dict(out_keys);
    nf = length(out_keys);
    info = cell(nsig, nf);
    found = false(nsig, 1);
    info(:,  field_dict(args.query_field)) = q;
    for ii=1:nchunk
        st = (ii-1)*args.max_list_size+1;
        stp = min(st + args.max_list_size - 1, nsig);
        cursor = m.findFromList(args.query_field, q(st:stp), keys);
        while(cursor.hasNext)
            doc = cursor.next;
            ridx = sig_dict(doc.get(args.query_field));
            found(ridx) = true;
            k = doc.keySet.toArray.cell;
            v = doc.values.toArray.cell;
            % fix for arrays in mongo doc
            vclass = cellfun(@class, v ,'uniformoutput', false);
            isdblist = strcmp(vclass,'com.mongodb.BasicDBList');
            if any(isdblist)
                v(isdblist) = cellfun(@(x) cell(x.toArray), v(isdblist),...
                    'uniformoutput', false);
            end
            % fix dbobjects
            isdbobject = find(strcmp(vclass,'com.mongodb.BasicDBObject'));
            
%             for jj=1:length(isdbobject)
%                 d = mortar.containers.Dict();
%                 eset = v{isdbobject(jj)}.entrySet;
%                 it = eset.iterator;
%                 while (it.hasNext)
%                     e = it.next;
%                     d(e.getKey) = e.getValue;
%                 end
%                 v{isdbobject(jj)} = d;
%             end
            v(isdbobject) = cellfun(@(x) mortar.containers.Dict(...
                                 validvar(cell(x.keySet.toArray)),...
                                 cell(x.values.toArray)),...
                                v(isdbobject),...
                                'uniformoutput', false);
            
%             keep = field_dict.iskey(k);
            keep = field_dict.isKey(k);
            cidx = field_dict.values(k(keep));
            cidx = cat(1, cidx{:});
            info(ridx, cidx) = v(keep);
        end
    end
    
    if has_dup
        info = info(iuq, :);
    end
else
    keys = args.fields;
    out_keys = regexprep(keys, '\..*', '');
%     field_dict = mortar.containers.Dict(out_keys);
    field_dict = list2dict(out_keys);
    cursor = m.find(query, keys);
    ndoc = cursor.size;
    nf = length(keys);
    info = cell(ndoc, nf);
    ctr = 1;
    while(cursor.hasNext)
        doc = cursor.next;
        k = doc.keySet.toArray.cell;
        v = doc.values.toArray.cell;
%         keep = field_dict.iskey(k);
        keep = field_dict.isKey(k);
        cidx = field_dict.values(k(keep));
        cidx = cat(1, cidx{:});
        info(ctr, cidx) = v(keep);
        ctr = ctr + 1;
    end
end

if ~args.as_cell
    info = cell2struct(info, validvar(out_keys,'_'), 2);
end

end

function default = get_collection_defaults(mongo_collection, defaults_file)

default = struct('fields', '', 'query_field', '');
dflt = parse_gmt(defaults_file);
idx = strcmpi(mongo_collection, {dflt.head});
if any(idx)
    default.query_field = dflt(idx).desc;
    default.fields = dflt(idx).entry;
end

end

