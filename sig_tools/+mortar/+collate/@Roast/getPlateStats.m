function [rpt, status_rpt] = getPlateStats(plate_path, plate_pat)
% Collate GEX roast QC stats

[fn, fp] = find_file(fullfile(plate_path, plate_pat));

nplate = length(fn);
dbg(1, '%d plates found in %s', nplate, plate_path);

rpt = struct('det_plate', fn);

status_rpt = struct('det_plate', fn,...
                'status', 'pass');
            
bfpt_fields = {'det_plate',...
               'rna_plate',...
               'pert_plate',...
               'brew_id',...
               'cell_id',...
               'pert_time',...
               'replicate',...
               'bset_id',...
               'scanner_id',...
               'scan_date',...
               'n_scanned_wells',...
               'count_mean',...
               'plate_lvl10',...
               'span_plate',...
               'range_plate',...
               'frac_good_qcode'};

poscon_fields = {'plate_id', 'pert_id', 'cmap_rank'};           

for ii=1:nplate
% find entmoot reports

[ent_fn, ent_fp] = find_file(fullfile(fp{ii}, 'entmoot', '*_ENTMOOT.txt'));
if ~isempty(ent_fn)
    ent_tbl = parse_record(ent_fp{1});
    rpt = join_table(rpt, ent_tbl, 'det_plate', 'det_plate', bfpt_fields);
end

[poscon_fn, poscon_fp] = find_file(fullfile(fp{ii}, 'poscon', 'connection_summary.txt'));

if ~isempty(poscon_fn)
    poscon_tbl = parse_record(poscon_fp{1});
    if all(isfield(poscon_tbl, poscon_fields))
        idx = gen_labels(length(poscon_tbl), 'prefix', 'n');
        poscon_tbl = setarrayfield(poscon_tbl, [], 'index', idx);
        ds_rank = tbl2gct(poscon_tbl, 'cmap_rank', 'index');
        row_meta = gctmeta(ds_rank, 'row');
        row_meta = keepfield(row_meta, {'rid', 'plate_id', 'pert_id'});
        ds_rank = annotate_ds(ds_rank, row_meta, 'dim', 'row', 'append', false);        
        ds_med_rank = ds_aggregate(ds_rank, 'row_fields', {'plate_id', 'pert_id'}, 'fun', 'median');
        ds_mom_rank = ds_aggregate(ds_med_rank, 'row_fields', {'plate_id'}, 'fun', 'median');
        mom_rank_tbl = gct2tbl(ds_mom_rank);
        rpt = join_table(rpt, mom_rank_tbl, 'det_plate', 'plate_id', 'cmap_rank');
    else
        dbg(1, '%s poscon table is missing required fields', fn{ii});
    end    
end


end

% BFPT report
% cat /cmap/obelix/pod/custom/CBRANT/roast/CBRANT*_C{5,6}/entmoot/CBRANT*_ENTMOOT.txt | awk -f /cmap/bin/deduphd.awk > bfpt.txt

% Poscon connectivity
% cat /cmap/obelix/pod/custom/CBRANT/roast/CBRANT*_C{5,6}/poscon/connection_summary.txt | awk -f /cmap/bin/deduphd.awk > poscon.txt

end