function [info, keys] = gene_info(q, varargin)
% GENE_INFO Get gene annotations from Mongo.
%   INFO = GENE_INFO(pr_id) Returns annotations for each probe id.
%   pr_id can be a string, cell array or a GRP file. INFO is a structure
%   with length(pr_id) rows.
%
%   Example:
%   gene_info({'201746_at', '211300_s_at'})

[info, keys] = mongo_info('gene_info', q, varargin{:});

% default_fields = {'pr_id', 'pr_gene_symbol', 'pr_gene_title',...
%                   'pr_gene_id', 'is_lm', 'is_gold'};
%       
% pnames = {'fields', 'mongo_location',...
%           'mongo_info',...
%           'max_list_size', 'as_cell'};
% dflts = {default_fields, 'current',...
%          mapdir(fullfile(mortarconfig('mongo_config_path'),'mongo_servers.txt')),...
%          50000, false};
% 
% args = parse_args(pnames, dflts, varargin{:});
% 
% isjson = false;
% if ischar(pr_id) && isfileexist(pr_id)
%     pr_id = parse_grp(pr_id);
% elseif ischar(pr_id) && pr_id(1)=='{'
%     %json input
%     query = parse_json(pr_id);
%     isjson = true;
% elseif ischar(pr_id)
%     pr_id = {pr_id};
% elseif ~iscell(pr_id)
%     error('Invalid pr_id')
% end
% 
% mdb = get_mongo_info(args.mongo_info, args.mongo_location);
% m = mortar.containers.Mongo(tokenize(mdb.replica_set, ',', true));
% 
% %assert(m.isConnected(), 'Could not connect to %s', mdb.server_id);
% ok = m.getDB(mdb.sig_db, mdb.user_id, mdb.password);
% assert (ok, 'Unable to authenticate to db:%s', mdb.sig_db);
% %ns = sprintf('%s.%s', mdb.sig_db, mdb.sig_collection);
% m.getCollection('gene_info');
% 
% if ~isjson
%     nsig = length(pr_id);
%     nf = length(args.fields);
%     assert(iscell(pr_id), 'pr_id must be a cell array or grp file');
%     assert(iscell(args.fields), 'fields must be a cell array');
%     
%     nchunk = ceil(nsig / args.max_list_size);
%     sig_dict = list2dict(pr_id);
%     keys = args.fields;
%     field_dict = list2dict(keys);
%     info = cell(nsig, nf);
%     info(:,1) = pr_id;
%     
%     for ii=1:nchunk
%         st = (ii-1)*args.max_list_size+1;
%         stp = min(st + args.max_list_size - 1, nsig);
%         cursor = m.findFromList('pr_id', pr_id(st:stp), keys);
%         while(cursor.hasNext)
%             doc = cursor.next;
%             ridx = sig_dict(doc.get('pr_id'));
%             k = doc.keySet.toArray.cell;
%             v = doc.values.toArray.cell;
%             % fix for arrays in mongo doc
%             vclass = cellfun(@class, v ,'uniformoutput', false);
%             isdblist = strcmp(vclass,'com.mongodb.BasicDBList');
%             if any(isdblist)
%                 v(isdblist) = cellfun(@(x) cell(x.toArray), v(isdblist),...
%                     'uniformoutput', false);
%             end
%             keep = field_dict.isKey(k);
%             cidx = field_dict.values(k(keep));
%             cidx = cat(1, cidx{:});
%             info(ridx, cidx) = v(keep);
%         end
%     end
% else
%     keys = args.fields;
%     field_dict = list2dict(keys);
%     cursor = m.find(query, keys);
%     ndoc = cursor.size;
%     nf = length(keys);
%     info = cell(ndoc, nf);
%     ctr = 1;
%     while(cursor.hasNext)
%         doc = cursor.next;
%         k = doc.keySet.toArray.cell;
%         v = doc.values.toArray.cell;
%         keep = field_dict.isKey(k);
%         cidx = field_dict.values(k(keep));
%         cidx = cat(1, cidx{:});
%         info(ctr, cidx) = v(keep);
%         ctr = ctr + 1;
%     end
% 
% end
% 
% if ~args.as_cell
%     info = cell2struct(info, keys, 2);
% end

end
