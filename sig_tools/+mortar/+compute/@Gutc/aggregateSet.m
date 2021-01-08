function agg_ds = aggregateSet(ds, meta, pcl, dim,...
                               match_field, aggregate_method, aggregate_param)
% aggregateSet Aggregate input matrix based on a grouping set
%   A = aggregateSet(DS, META, S) Aggregates rows of DS based on entries of
%   the set S. The output dataset A has as many rows as length(S). DS can
%   be a dataset structure or GCT(X) file. S can be a geneset structure or
%   GMT, GMX or GRP file. META is a table structure or TSV file with
%   alternate annotations required for aggregating DS. Row annotations of 
%   DS are required for dim =1 or 'column'. If META is empty annotations
%   are read from DS. 
%
%   A = aggregateSet(DS, META, S, DIM) Operates along dimension DIM. Valid
%   choices for DIM are [1],2 or {'column', 'row'}. If DIM is 1 or
%   'column', rows of DS are aggregated, otherwise columns of DS are
%   aggregated.
%
%   A = aggregateSet(DS, META, S, DIM, MATCH_FIELD) Indicate the meta-data
%   field to use for matching the ids in S to DS.
%
%   A = aggregateSet(DS, META, S, DIM, MATCH_FIELD, METHOD, METHOD_PARAM)
%   Specify aggregation method and parameters. Choices for METHOD are
%   {maxq}, median, mean. METHOD_PARAM is structure currenly required only
%   for maxq where the default is struct('q_low', 33, 'q_high', 67)

if ~isvarexist('dim')
    % aggregate rows
    dim = 1;
end
[dim_str, dim_val] = get_dim2d(dim);
agg_dim = 3 - dim_val;
if ~isvarexist('match_field')
    match_field = '_id';
end

if ~isvarexist('aggregate_method')
    aggregate_method = 'maxq';
end

if ~isvarexist('aggregate_param')
    aggregate_param = struct('q_low', 33, 'q_high', 67);
end

if mortar.util.File.isfile(pcl, 'file')
    pcl = parse_geneset(pcl);
end
id_pcl = setunion(pcl);

if mortar.util.File.isfile(ds)
    dsmeta = parse_gctx(ds, 'annot_only', true);
    ds_id = ds_get_meta(dsmeta, agg_dim, '_id');
    [cmn_id, idx] = intersect(ds_id, id_pcl);
    assert(~isempty(cmn_id), 'No common ids found in the dataset');
    if isequal(dim_str, 'row')
        ds = parse_gctx(ds, 'cid', dsmeta.cid(idx));
    else
        ds = parse_gctx(ds, 'rid', dsmeta.rid(idx));
    end
end

% extract annotations from the dataset if not provided separately
if ~isempty(meta)
    ds = annotate_ds(ds, meta, 'dim', agg_dim);
end

assert(all(is_ds_field(ds, match_field, agg_dim)),...
        'Required annotation field missing: %s', match_field);

% aggregate over each pcl
id_ds = ds_get_meta(ds, agg_dim, match_field);
[common_id, ipcl, ids] = intersect(id_pcl, id_ds);
% pert_id to row index in ds
id_dict = mortar.containers.Dict(common_id, ids);
npcl = length(pcl);
[nrow, ncol] = size(ds.mat);

switch (dim_str)
    case 'column'
        % aggregate rows
        res = nan(npcl, ncol);
        nmem = zeros(npcl, 1);
        for ii=1:npcl
            isk = id_dict.iskey(pcl(ii).entry);
            this_ridx = id_dict(pcl(ii).entry(isk));
            nmem(ii) = numel(this_ridx);
            %dbg(1, '%d/%d %s %d members', ii, npcl, pcl(ii).head, nmem(ii));
            if nmem(ii)>=2
                this_ds = ds_slice(ds, 'ridx', this_ridx);
                this_ds = ds_add_meta(this_ds, 'row', 'pert_id_pcl', ...
                    pcl(ii).head);
                this_agg = mortar.compute.Gutc.aggregateQuery(this_ds, [], ...
                    {'pert_id_pcl'}, ...
                    1, aggregate_method, ...
                    aggregate_param);
                res(ii, :) = this_agg.mat;
            else
                dbg(1, '%s: Only %d members, skipping', pcl(ii).head, nmem(ii));
            end
        end
        agg_ds = mkgctstruct(res, 'rid', {pcl.head}', 'cid', ds.cid);
        agg_ds = annotate_ds(agg_ds, gctmeta(ds), 'dim', 'column');
        agg_ds = ds_add_meta(agg_ds, 'row', 'pcl_size', num2cell(nmem));
    case 'row'
        % aggregate columns
        res = nan(nrow, npcl);
        nmem = zeros(npcl, 1);
        for ii=1:npcl
            isk = id_dict.iskey(pcl(ii).entry);
            this_cidx = id_dict(pcl(ii).entry(isk));
            nmem(ii) = numel(this_cidx);
            dbg(1, '%d/%d %s %d members', ii, npcl, pcl(ii).head, nmem(ii));
            if nmem(ii)>=2
                this_ds = ds_slice(ds, 'cidx', this_cidx);
                this_ds = ds_add_meta(this_ds, 'column', 'pert_id_pcl', ...
                    pcl(ii).head);
                this_agg = mortar.compute.Gutc.aggregateQuery(this_ds, [], ...
                    {'pert_id_pcl'}, ...
                    2, aggregate_method, ...
                    aggregate_param);
                res(:, ii) = this_agg.mat;
            else
                dbg(1, '%s: Only %d members, skipping', pcl(ii).head, nmem(ii));
            end
        end
        agg_ds = mkgctstruct(res, 'cid', {pcl.head}', 'rid', ds.rid);
        agg_ds = annotate_ds(agg_ds, gctmeta(ds, 'row'), 'dim', 'row');
        agg_ds = ds_add_meta(agg_ds, 'column', 'pcl_size', num2cell(nmem));
    otherwise
        error('Invalid dim: %s', dim_str);
end

end
