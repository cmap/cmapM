function agg_ds = aggregateSetByCell(ds, meta, pcl, dim,...
                               match_field, aggregate_method,...
                               aggregate_param)
% aggregateSetByCell Aggregate input matrix based on a grouping set split
%                    by cell line
%   A = aggregateSetByCell(DS, META, S) Aggregates rows of DS based on entries of
%   the set S. The output dataset A has as many rows as length(S). DS can
%   be a dataset structure or GCT(X) file. S can be a geneset structure or
%   GMT, GMX or GRP file. META is a table structure or TSV file alternate annotations required for aggregating DS. Row annotations of 
%   DS are required for dim =1 or 'column'. If META is empty annotations
%   are read from DS. 
%
%   A = aggregateSet(DS, META, S, DIM) Operates along dimension DIM. Valid
%   choices for DIM are [1],2. If DIM is 1 rows of DS are aggregated, else
%   columns of DS are aggregated
%
%   A = aggregateSet(DS, META, S, DIM, MATCH_FIELD) Indicate the meta-data
%   field to use for matching the ids in S to DS.
%
%   A = aggregateSet(DS, META, S, DIM, MATCH_FIELD, METHOD, METHOD_PARAM) Specify aggregation
%   method and parameters. Choices for METHOD are {maxq}, median, mean.
%   METHOD_PARAM is structure currenly required only for maxq where the
%   default is struct('q_low', 33, 'q_high', 67)

if ~isvarexist('dim')
    % default to aggregate rows
    dim = 1;
end
[dim_str, dim_val] = get_dim2d(dim);
% aggregation dimension
agg_dim = 3-dim_val;
if ~isvarexist('match_field')
    match_field = 'pert_id';
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
    if ~isempty(meta)
        dsmeta = annotate_ds(dsmeta, meta, 'dim', agg_dim);
    end
    ds_id = ds_get_meta(dsmeta, agg_dim, match_field);
    idx = ismember(ds_id, id_pcl);
    assert(~isempty(idx), 'No common ids found in the dataset');
    if isequal(dim_str, 'row')
        ds = parse_gctx(ds, 'cid', dsmeta.cid(idx));
    else
        ds = parse_gctx(ds, 'rid', dsmeta.rid(idx));
    end
end

% Use annotations from the dataset if provided separately
if ~isempty(meta)
    ds = annotate_ds(ds, meta, 'dim', agg_dim);
end

% match_field and a cell_id must exist in meta
assert(all(is_ds_field(ds, match_field, agg_dim)),...
        'Required annotation field missing: %s', match_field);
assert(all(is_ds_field(ds, 'cell_id', agg_dim)),...
        'Required annotation field missing: cell_id');
    
%% Aggregate by cell line
switch dim_str
    case 'column'
        % aggregate rows
        cell_id = ds_get_meta(ds, 'row', 'cell_id');
        [cell_gp, cell_idx] = getcls(cell_id);
        ncell = length(cell_gp);
        for ic = 1:ncell
            dbg(1, '%d/%d %s', ic, ncell, cell_gp{ic});
            this_rid = cell_idx == ic;
            this_ds = ds_slice(ds, 'rid', ds.rid(this_rid));
            this_norm = mortar.compute.Gutc.aggregateSet(this_ds, [], pcl, ...
                            'column', match_field, aggregate_method,...
                            aggregate_param);
            % append cell line to PCL ID
            this_norm.rid = strcat(this_norm.rid, ':', cell_gp{ic});
            if isequal(ic, 1)
                agg_ds = this_norm;
            else
                agg_ds = merge_two(agg_ds, this_norm);
            end
        end
    case 'row'
        % aggregate columns
        cell_id = ds_get_meta(ds, 'column', 'cell_id');
        [cell_gp, cell_idx] = getcls(cell_id);
        ncell = length(cell_gp);
        for ic = 1:ncell
            dbg(1, '%d/%d %s', ic, ncell, cell_gp{ic});
            this_cid = cell_idx == ic;
            this_ds = ds_slice(ds, 'cid', ds.cid(this_cid));
            this_norm = mortar.compute.Gutc.aggregateSet(this_ds, [], pcl, ...
                            'row', match_field, aggregate_method,...
                            aggregate_param);
            % append cell line to PCL ID
            this_norm.cid = strcat(this_norm.cid, ':', cell_gp{ic});
            if isequal(ic, 1)
                agg_ds = this_norm;
            else
                agg_ds = merge_two(agg_ds, this_norm);
            end
        end
    otherwise
        error('Invalid dim: %s', dim_str);
end

agg_ds = ds_delete_missing(agg_ds);

end
