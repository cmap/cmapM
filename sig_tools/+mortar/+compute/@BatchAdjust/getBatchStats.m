function batch_stats = getBatchStats(ds, dim, batch)
% getBatchStats Batch group statistics
% S = getBatchStats(DS, DIM, BATCH_FIELD) returns a structure with
% statistics computed on the dataset DS per unique entry for BATCH_FIELD
% along the dimension DIM

ds = parse_gctx(ds);
[dim_str, dim_val] = get_dim2d(dim);

switch(dim_str)
    case 'column'
        [gpv, gpn, gpi, ~, gpsz] = get_groupvar(ds.cdesc, ds.chd, batch);
        [batch_id, batch_mean_perrow, batch_std_perrow] =  grpstats(ds.mat', gpv, {'gname', 'nanmean', 'nanstd'});
        batch_mean = mean(batch_mean_perrow, 2);
        batch_std = mean(batch_std_perrow, [], 2);        
    case 'row'
        [gpv, gpn, gpi, ~, gpsz] = get_groupvar(ds.rdesc, ds.rhd, batch);
        [batch_id, batch_mean_percol, batch_std_percol] =  grpstats(ds.mat, gpv, {'gname', 'nanmean', 'nanstd'});
        % Aggregate per sample stats
        batch_mean = mean(batch_mean_percol, 2);
        batch_std = mean(batch_std_percol, 2);
        % TODO add confidence intervals
end

batch_stats = struct('batch_id', batch_id,...
                     'batch_size', num2cell(gpsz),...
                     'batch_mean', num2cell(batch_mean),...
                     'batch_std', num2cell(batch_std));
end