function createDigestTables(ds, out_path, args)
    col_meta = gctmeta(ds, 'column');
    
    % header for data columns
    val_field = get_groupvar(col_meta, fieldnames(col_meta), ...
                             args.digest_header);
    % sort headers
    [val_field, order] = orderas(val_field, ['summary';unique(val_field)]);
    val_fieldname = validvar(val_field, '_');
    
    ds = ds_slice(ds, 'cidx', order);
    % grouping columns for each digest
    [gpv, gpn, gpi, fn, gpsz] = get_groupvar(ds.cdesc, ds.chd, ...
                                             args.digest_group);

    table_path = fullfile(out_path, 'src');
    if ~isdirexist(table_path)
        mkdir (table_path);
    end

    nc = length(gpn);
    row_meta = gctmeta(ds, 'row');
    row_meta = keepfield(row_meta, intersect(fieldnames(row_meta), {'pert_id', ...
                        'pert_iname','pert_type'}));
    
    [~, uidx] = unique(gpi, 'stable');
    
    % index content
    index_field = intersect(ds.chd, union(args.index_header, args.digest_group));
    index_field = orderas(index_field, args.index_header);
    ifield = cell2mat(ds.cdict.values((index_field)));
    if isempty(index_field)
        index = struct('query_id', ds.cid(uidx), 'url', '');
    else
        index = cell2struct(ds.cdesc(uidx, ifield), ...
                          index_field, 2);       
    end
    
    for ii=1:nc
        rpt = row_meta;
        cidx = gpi == ii;
        v = ds.mat(:, cidx);
        % set nans to 0.0666 for sorting the HTML the table
        v(isnan(v)) = 0.0666;

        vfn = val_fieldname(cidx);
        vhd = val_field(cidx);
        for jj=1:size(vfn)
            vc = num2cell(v(:, jj));
            [rpt.(vfn{jj})] = vc{:};
        end
        [~, table_file] = validate_fname(fullfile(table_path, sprintf('%s.txt', ...
                                                          gpn{ii})), '_');
        index(ii).url = path_relative_to(out_path, table_file);
        hd = fieldnames(rpt);
        [~, ihd, ivhd] = intersect(hd, vfn);
        hd(ihd) = vhd(ivhd);
        jmktbl(table_file, rpt, 'verbose', false, 'header', hd);
        print_ticker(ii, 10, nc, 1);
    end

    % create index file
    index_file = fullfile(out_path, 'index.txt');
    jmktbl(index_file, index);
end