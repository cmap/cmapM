function plotJellyfish(rankpt_ds, gpset, args, wkdir, prefix)
% plot pw matrices
    plot_length = args.plot_tail;
    ngps = numel(gpset);
    meta = gctmeta(rankpt_ds);
    
    gct_tmpdir = tempname;
    mkdirnotexist(gct_tmpdir);

    outpath = fullfile(wkdir, prefix);
    mkdirnotexist(fullfile(outpath, 'jellyfish'));
    list = cell(ngps, 1);
    for ii = 1:ngps
        gp_idx = find(ismember({meta.(args.match_field)}, gpset(ii).entry));
        nx = nnz(gp_idx);
        if nx > 1
            gp_ds = ds_slice(rankpt_ds, 'cidx', gp_idx);
            gp_meta = gctmeta(gp_ds, 'row');
            nrows = size(gp_ds.mat, 1);
            
            row_q25 = q25(gp_ds.mat, 2);
            row_medians = median(gp_ds.mat, 2);
            row_q75 = q75(gp_ds.mat, 2);

            [~, order_idx] = sort(row_medians, 'descend');
          
            %add ranks to metadata
            rank = 1:numel(order_idx);
            rank(order_idx) = rank;
            rank = num2cell(rank);
            [gp_meta.rank] = rank{:};
            
            row_medians = num2cell(row_medians);
            [gp_meta.median] = row_medians{:};
            row_q25 = num2cell(row_q25);
            [gp_meta.q25] = row_q25{:};
            row_q75 = num2cell(row_q75);
            [gp_meta.q75] = row_q75{:};
            
            %find set member rows
            is_moa = zeros(nrows, 1);
            is_moa(gp_idx) = 1;
            is_moa = num2cell(is_moa);
            [gp_meta.is_moa] = is_moa{:};
            
            %set members
            list_top = intersect(order_idx, gp_idx, 'stable');
            %non set
            list_bottom = setdiff(order_idx, gp_idx, 'stable');

            gp_ds = annotate_ds(gp_ds, gp_meta, 'dim', 'row'); 

            switch (args.cluster_method)
                case 'hclust'
                    % re-order matrix based on hclust
                    set_ds = ds_slice(gp_ds, 'ridx', gp_idx);
                    [set_ds, ord] = hclust(set_ds, 'make_symmetric', true);
                    off_ds = ds_slice(gp_ds, 'ridx', list_bottom, 'cidx', ord);
                    sorted_ds = merge_two(set_ds, off_ds);
                case 'median'
                    order_idx = [list_top; list_bottom];
                    sorted_ds = ds_order(gp_ds, 'column', order_idx);

                    [~, col_ord] = sort(row_medians(gp_idx), 'descend');
                    sorted_ds = ds_order(sorted_ds, 'row', col_ord);
                otherwise
                    error ('Invalid cluster method:%s', args.cluster_method);
            end            

            plot_length = min(plot_length, nrows);
            plot_ds = ds_slice(sorted_ds, 'ridx', 1:plot_length);

            ofile = mkgctx(fullfile(outpath,'jellyfish',sprintf('%s_%s.gctx', ...
                char(validvar(gpset(ii).head)), prefix)), plot_ds);


            tail = sorted_ds.mat(numel(list_top)+1:end, :);
            rpt(ii).moa = gpset(ii).head;
            rpt(ii).ncps = numel(gpset(ii).entry);
            cl_fn = validvar(prefix);
            tail_fa95 = nnz(tail > 95)/numel(tail);  
            rpt(ii).(cl_fn{1}) = tail_fa95;  
            
            title = sprintf('%s_%s_%d_rows_%0.3f_fa95', gpset(ii).head, prefix, nrows,tail_fa95);

            outname = fullfile(outpath,'jellyfish', validvar(sprintf('jellyfish_%s', gpset(ii).head), '_'));
            
            if args.make_heatmap
                list{ii} = mkheatmap(ofile,...
                    outname{1},...
                    'title', title, ...
                    'color_scheme', args.jf_color_scheme, ... 
                    'column_text', args.jf_col_text, ...
                    'row_text',  args.jf_row_text, ...
                    'row_color', {'is_moa'});    
            end

        elseif (nx == 0)
            rpt(ii).moa = gpset(ii).head;
            rpt(ii).ncps = numel(gpset(ii).entry);
            cl_fn = validvar(prefix);
            rpt(ii).(cl_fn{1}) = nan;  
            dbg(1, 'no members found, skipping');
        else
            rpt(ii).moa = gpset(ii).head;
            rpt(ii).ncps = numel(gpset(ii).entry);
            cl_fn = validvar(prefix);
            rpt(ii).(cl_fn{1}) = nan;  
            dbg(1, 'singleton, skipping');
        end  
    end

    list(cellfun(@isempty, list)) = []; %delete empty cells
    if ~isempty(list)
        mkgallery(fullfile(outpath, 'jellyfish', 'index.html'), list);
    end
    mktbl(fullfile(outpath, 'tail_fa95.txt'), rpt');
end
