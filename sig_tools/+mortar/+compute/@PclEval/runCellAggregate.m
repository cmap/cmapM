function rpt = runCellAggregate(dspath, full_meta, pcl, varargin)

    pnames = {'out', ...
        'match_field', ...
        'sort_fields', ...
        'cluster_method', 'fig_size', ...
        'cell_sens', 'colormap'};

    dflts = {pwd, ...
        'pert_iname', ...
        {'num_sens', 'sens_line_corr'}, ...
        'fields', 800, ...
        0.33, 'taumap_redblue90'};

    args = parse_args(pnames, dflts, varargin{:});

    HM_GALLERY = 'heatmap_gallery.html';
    HTML_TBL_OUT = 'cell_aggregate.html';
    
    SCALE = 100;
    PCT90 = .90;
    PCT95 = .95;
    HEATMAP_SCALE = PCT95;
    
    META_SENS_FIELD = 'is_sensitive_72h';
    
    
    CELL_SENS = args.cell_sens;
    SENS_FIELD = 'cline_sensitive';
    CORR_FIELD = 'sens_line_corr';
    SORT_FIELDS = {SENS_FIELD, CORR_FIELD};
    
    COLOR_FIELDS = {SENS_FIELD};
    ROW_FIELDS =  {'cell_id'};
    COL_FIELDS = {'cell_id'};
    
    fprintf('Generating heatmaps sorting by: %s\n\n', args.cluster_method);
    
    ds = parse_gctx(dspath, 'annot_only', true);
    ds = annotate_ds(ds, full_meta); 
    ds = annotate_ds(ds, full_meta, 'dim', 'row');
    siginfo = gctmeta(ds);

    if isstruct(pcl)
        moas = pcl;
    elseif isfileexist(pcl)
        moas = parse_geneset(pcl);
    else
        error('pcl file not found: %s \n', pcl);
    end
    
    rpt = struct('moa', [], 'moa_size', []); %% make some report
    
    mkdirnotexist(args.out);
    mkdirnotexist(fullfile(args.out, 'heatmaps'));
    mkdirnotexist(fullfile(args.out, 'gct'));
    for ii = 1:numel(moas)
        NAME = moas(ii).head;
        idx = ismember({siginfo.(args.match_field)}, moas(ii).entry);
        num_sigs = nnz(idx);
        fprintf('%d entries with moa: %s\n', num_sigs, NAME);
        if nnz(idx) == 0
            continue
        end
        ds_moa = ds_slice(ds, 'cidx', idx, 'ridx', idx);
        ds_moa = parse_gctx(dspath,'cid', ds_moa.cid,'rid',ds_moa.rid);
        ds_moa = annotate_ds(ds_moa, siginfo); 
        ds_moa = annotate_ds(ds_moa, siginfo, 'dim', 'row'); 
        
        n_cps = numel(unique(ds_moa.cdesc(:,ds_moa.cdict('pert_iname'))));

        agg_row_first = ds_aggregate(ds_moa, 'row_fields', 'cell_id', 'col_fields', 'cell_id', 'fun', 'median');
        agg_col_first = ds_aggregate(ds_moa, 'row_fields', 'cell_id', 'col_fields', 'cell_id', 'fun', 'median', 'rows_first', false);

        agg_ds = agg_row_first;
        agg_ds.mat = (agg_row_first.mat + agg_col_first.mat)/2;
        
        
        rpt(ii).moa = NAME;
        rpt(ii).moa_size = n_cps;

        %% Sort 
     
        clear ord
        switch (args.cluster_method)
            case 'hclust'
                % re-order matrix based on hclust
                [~, ord] = hclust(agg_ds, 'make_symmetric', true);
                
                fig_title = sprintf('%s_%d_cps', NAME, n_cps);
            case 'median'
                row_medians = median(agg_ds.mat, 2);
                [~, ord] = sort(row_medians, 'descend');         
                
                fig_title = sprintf('%s_%d_cps', NAME, n_cps);
            case 'fields'       %sorts by fields and get stats on sensitivity
                full_meta = gctmeta(ds_moa);
                cells = unique({full_meta.cell_id});
        
                total_sensitive = 0;    %marked as sensitive for figure annot
                cline_sensitive = cell(numel(cells), 1);
                nsens_per_cline = nan(numel(cells), 1);
                nsigs_per_cline = nan(numel(cells), 1);
                for jj = 1:numel(cells)
                    tmp_meta = full_meta(strcmp({full_meta.cell_id}, cells{jj}));
                    nsigs_per_cline(jj) = numel(tmp_meta);
                    nsens_per_cline(jj) = nnz(strcmp({tmp_meta(META_SENS_FIELD)}, '1'));
                    if (nnz(strcmp({tmp_meta(META_SENS_FIELD)}, '1'))/numel(tmp_meta) > CELL_SENS)
                        total_sensitive = total_sensitive + 1;                
                        cline_sensitive(jj) = {'1'};
                    else
                        cline_sensitive(jj) = {'0'};
                    end
                end
                
                % Add metrics to annotations
                info = gctmeta(agg_ds);

                idx = strcmp(cline_sensitive, '1');
                sens_cells = agg_ds.mat(:, idx);
                sens_vector = median(sens_cells,2); 
                corr_to_sens_lines = fastcorr(agg_ds.mat, sens_vector);

                tmp = num2cell(nsens_per_cline);
                [info.num_sens] = tmp{:};   
                tmp = num2cell(corr_to_sens_lines);
                [info.(SENS_FIELD)] = cline_sensitive{:};
                [info.(CORR_FIELD)] = tmp{:};

                agg_ds = annotate_ds(agg_ds, info);
                agg_ds = annotate_ds(agg_ds, info, 'dim', 'row');  
                
                clear tab
                tab = struct2table(info);
                [~,ord]  = sortrows(tab,SORT_FIELDS, 'ascend');  

                agg_info = gctmeta(agg_ds_sorted);  
    
                if iscellstr({agg_info.(SENS_FIELD)})
                    nsens = nnz(strcmp({agg_info.(SENS_FIELD)}, '1'));
                    ninsens = nnz(~strcmp({info.(SENS_FIELD)}, '1'));
                    sens_idx = strcmp({agg_info.(SENS_FIELD)}, '1');
                    insens_idx = find(~strcmp({agg_info.(SENS_FIELD)}, '1'));
                else
                    nsens = nnz([agg_info.(SENS_FIELD)] == 1 );
                    ninsens = nnz([agg_info.(SENS_FIELD)] ~= 1);
                    sens_idx = logical([agg_info.(SENS_FIELD)] == 1);
                    insens_idx = ~logical([agg_info.(SENS_FIELD)] == 1);
                end

                insens_data = ds_slice(agg_ds_sorted, 'cidx', insens_idx, 'ridx', insens_idx);

                sens_data = ds_slice(agg_ds_sorted, 'cidx', sens_idx,'ridx', sens_idx);

                sens = sens_data.mat;
                sens(find(eye(size(sens)))) = nan;

                insens = insens_data.mat;
                insens(find(eye(size(insens)))) = nan;

                sens_vals = sens(find(triu(ones(size(sens)),1)));
                insens_vals = insens(find(triu(ones(size(insens)),1)));  
                
                % Sensitivity stats
                rpt(ii).nsens = nsens;
                rpt(ii).n_insens = ninsens;
                rpt(ii).moa_nsens = nsens;
                rpt(ii).moa_n_insens = ninsens;
                rpt(ii).median_sens = nanmedian(nanmedian(sens_vals));
                rpt(ii).median_insens = nanmedian(nanmedian(insens_vals));             
                rpt(ii).fraction_sens30 = nnz(sens_vals > .30 * SCALE) / (numel(sens_vals));    
                rpt(ii).fraction_insens30 = nnz(insens_vals > .30 * SCALE) / (numel(insens_vals));
                rpt(ii).fraction_sens50 = nnz(sens_vals > .50 * SCALE) / (numel(sens_vals));
                rpt(ii).fraction_insens50 = nnz(insens_vals > .50 * SCALE) / (numel(insens_vals));
                rpt(ii).fraction_sens70 = nnz(sens_vals > .70 * SCALE) / (numel(sens_vals));
                rpt(ii).fraction_insens70 = nnz(insens_vals > .70 * SCALE) / (numel(insens_vals));
                rpt(ii).fraction_sens_pct90 = nnz(sens_vals > .9 * SCALE) / (numel(sens_vals));
                rpt(ii).fraction_insens_pct90 = nnz(insens_vals > .9 * SCALE) / (numel(insens_vals)); 
                rpt(ii).fraction_sens_pct95 = nnz(sens_vals > .95 * SCALE) / (numel(sens_vals));
                rpt(ii).fraction_insens_pct95 = nnz(insens_vals > .95 * SCALE) / (numel(insens_vals));
                
                fig_title = sprintf('%s_%d_cps_%d_sens', NAME, n_cps, total_sensitive);
            otherwise
                error ('Invalid cluster method:%s', args.cluster_method);
        end
  
        agg_ds_sorted = mkgctstruct(agg_ds.mat(ord, ord), 'rid', agg_ds.rid(ord), 'cid', agg_ds.cid(ord), ...
        'rhd', agg_ds.rhd, 'chd', agg_ds.chd, ...
        'rdesc', agg_ds.rdesc(ord, :), 'cdesc', agg_ds.cdesc(ord, :)); 
    
    
        fprintf('Outputting GCT: %s\n ', fullfile(args.out, 'gct', NAME));
        ofile = mkgct(fullfile(args.out, 'gct', NAME), agg_ds_sorted);     
        
        color_scheme = sprintf('\\-%0.2f:#0000FF,\\-%0.2f:#FFFFFF,%0.2f:#FFFFFF,%0.2f:#FF0000', ...
            SCALE, HEATMAP_SCALE * SCALE, HEATMAP_SCALE * SCALE, SCALE);
        
        htmp_url = mkheatmap(ofile, fullfile(args.out, 'heatmaps', [moas(ii).head '.png']), ...
            'title', fig_title, ...
            'color_scheme', color_scheme, ...
            'column_color', COLOR_FIELDS, ...
            'row_color', COLOR_FIELDS, ...    
            'column_text', COL_FIELDS, ...
            'row_text', ROW_FIELDS);        
        
        rpt(ii).url = htmp_url;
        
%         close all
%         makeHeatmap(agg_ds,...
%             'show_figure',  false,...
%             'col_annots', {'cell_id', 'num_sens'}, ...
%             'row_annots', {'cell_id', 'num_sens'}, ...
%             'cluster_method', args.cluster_method, ...
%             'sort_fields', args.sort_fields,...
%             'colormap', args.colormap);
%         %xlabel('Cell Lines');
%         title({sprintf('moa: %s', moas(ii).head),sprintf('n_cps: %d', n_cps)}, 'FontSize', 12, 'Interpreter','none');
%         annot = sprintf('Number of sensitive\ncell lines:\n %d', total_sensitive);
%         annot = sprintf('%s\nNumber of compounds\nin MoA:\n %d', annot, n_cps);
%         annot = sprintf('%s\nNumber of signatures\nper cell line:\n %d', annot, median(nsigs_per_cline));
%         an_h = annotation('textbox', [0.84, 0.64, 0, 0], 'string', annot, ...
%             'FitBoxToText', 'on', 'LineStyle', 'none', ...
%             'FontUnits', 'normalized', 'FontSize', 0.0084);
%         %set(an_h, 'position', [0.8400    0.6144    0.1100    0.1056])
%         saveas(gcf, fullfile(args.out, 'heatmaps', [moas(ii).head, '_cell_agg']), 'png');
    end
    
    rpt = trim_empty_rows(rpt);
    
    [~,list] = find_file(fullfile(args.out, 'heatmaps', '*.png'));
    mkgallery(fullfile(args.out,HM_GALLERY), list);

    mk_html_table(fullfile(args.out,HTML_TBL_OUT), rpt');
    
end

function rpt = trim_empty_rows(rpt)
    tf = false(numel(rpt),1);
    for i = 1:numel(rpt)
        tf(i) = isempty(rpt(i).url);
    end
    rpt(tf) = [];
end
