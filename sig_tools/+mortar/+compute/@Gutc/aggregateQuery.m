function aggds = aggregateQuery(rp, meta, group, dim, aggregate_method, aggregate_param)
% AGGREGATEQUERY Aggregate query matrix based on a grouping variable.
%   A = AGGREGATEQUERY(RP, META, G)
%   A = AGGREGATEQUERY(RP, META, G, DIM)
%   A = AGGREGATEQUERY(RP, META, G, DIM, STATFN)

if ~isvarexist('dim')
    dim = 1;
end
[dim_str, dim_val] = get_dim2d(dim);

% aggregation function
switch(lower(aggregate_method))
    case 'maxq'
        % needs [lo, hi] quantile
        assert(all(ismember({'q_low', 'q_high'}, fieldnames(aggregate_param))),...
               'Required aggregation parameters for maxq missing, expected q_low, q_high, found %s',...
               print_dlm_line(fieldnames(aggregate_param)));
        statfn = @(x) max_quantile(x, aggregate_param.q_low, aggregate_param.q_high, 1);
    case 'median'
        statfn = @(x) nanmedian(x, 1);
    case 'mean'
        statfn = @(x) nanmean(x, 1);
    otherwise
        error('Unsupported aggregation function: %s', aggregate_method);        
end

% extract annotations from the dataset if not provided separately
if isempty(meta)
    meta = gctmeta(rp, 3-dim_val);    
end

fn = fieldnames(meta);
id_field = fn{~cellfun(@isempty, regexp(fn, '^[rc]*id$'))};
assert(~isempty(id_field), 'MetaIDFieldMissing');
 
switch dim_val
    case 1
        % aggregate rows
        if ~isequal(rp.rid, {meta.(id_field)}')
            [~, ~, srti] = intersect(rp.rid, {meta.(id_field)}, 'stable');
            meta = meta(srti);
            assert(isequal(rp.rid, {meta.(id_field)}'), 'Annotation mismatch');
        end
        
        [gpv, gpn, gpi, ~, gpsz] = get_groupvar(meta, fieldnames(meta), group);
        ng = length(gpn);
        
        [~, nc] = size(rp.mat);
        agg = zeros(ng, nc);
        gpn2idx = mortar.containers.Dict(gpn);
        is_singleton = gpsz<2;
        
        % singletons
        [~, ia] = intersect(gpv, gpn(is_singleton), 'stable');
        agg(is_singleton, :) = rp.mat(ia, :);
        
        % aggregate non-singletons
        ns_idx = find(~is_singleton);
        nns = length(ns_idx);
        for ii=1:nns
            this = gpi == ns_idx(ii);
            agg(gpn2idx(gpn(ns_idx(ii))), :) = statfn(rp.mat(this, :));
%             print_ticker(ii, 100, nns, 1);
        end
%         is_non_singleton = ismember(gpv, gpn(~is_singleton));        
%         [id, v] = grpstats(rp.mat(is_non_singleton, :), gpv(is_non_singleton),...
%             {'gname', statfn});
%         [~, ridx] = intersect_ord(gpn, id);
%         agg(ridx, :) = v;

        % row and column ids
        rid = gpn;
        cid = rp.cid;
        col_meta = gctmeta(rp, 1);
        row_meta = get_agg_meta(meta, id_field, gpi, gpn);
        if ~isequal(id_field, 'rid')
            row_meta = mvfield(row_meta, id_field, 'rid');
        end

%         row_meta = mvfield(row_meta, 'id', 'rid');
    case 2
        % aggregate columns
        if ~isequal(rp.cid, {meta.(id_field)}')
            [~, ~, srti] = intersect(rp.cid, {meta.(id_field)}, 'stable');
            meta = meta(srti);
            assert(isequal(rp.cid, {meta.(id_field)}'), 'Annotation mismatch');
        end
        
        [gpv, gpn, gpi, ~, gpsz] = get_groupvar(meta, fieldnames(meta), group);
        ng = length(gpn);
        
        [nr, ~] = size(rp.mat);
        agg = zeros(nr, ng);
        is_singleton = gpsz<2;
        
        % singletons
        [~, ia] = intersect(gpv, gpn(is_singleton), 'stable');
        agg(:, is_singleton) = rp.mat(:, ia);
        
        gpn2idx = mortar.containers.Dict(gpn);
        % aggregate non-singletons
        ns_idx = find(~is_singleton);
        nns = length(ns_idx);
        for ii=1:nns
            this = gpi == ns_idx(ii);
            agg(:, gpn2idx(gpn(ns_idx(ii)))) = statfn(rp.mat(:, this)');            
        end
%         % aggregate non-singletons
%         is_non_singleton = ismember(gpv, gpn(~is_singleton));
%         [id, v] = grpstats(rp.mat(:, is_non_singleton)', gpv(is_non_singleton),...
%             {'gname', statfn});
%         v = v';
%         [~, cidx] = intersect_ord(gpn, id);
%         agg(:, cidx) = v;

        % row and column ids
        rid = rp.rid;
        cid = gpn;
        
        row_meta = gctmeta(rp, 2);
        col_meta = get_agg_meta(meta, id_field, gpi, gpn);
        if ~isequal(id_field, 'cid')
            col_meta = mvfield(col_meta, id_field, 'cid');
        end
        
    otherwise
        error ('Unknown dimension specified, expected 1 or 2');
end
aggds = mkgctstruct(agg, 'rid', rid, 'cid', cid);
aggds = annotate_ds(aggds, row_meta, 'keyfield', 'rid', 'dim', 'row');
aggds = annotate_ds(aggds, col_meta, 'keyfield', 'cid', 'dim', 'column');

% % aggregate metadata for the 
% [~, uidx] = unique(gpi, 'stable');
% aggmeta = meta(uidx);
% % replace original id field
% aggmeta = rmfield(aggmeta, id_field);
% [aggmeta.id] = gpn{:};

end


function aggmeta = get_agg_meta(meta, id_field, gpi, gpn)
% aggregate metadata for the 
[~, uidx] = unique(gpi, 'stable');
aggmeta = meta(uidx);
% replace original id field
% aggmeta = rmfield(aggmeta, id_field);
[aggmeta.(id_field)] = gpn{:};
end
