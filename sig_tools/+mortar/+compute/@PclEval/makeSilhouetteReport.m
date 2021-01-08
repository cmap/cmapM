function [rpt, sil_gct] = makeSilhouetteReport(ds_path,siginfo_path, gpset, args)

    ds = parse_gctx(ds_path);
    ds = annotate_ds(ds, siginfo_path, 'dim', 'row', 'fieldnames', {'moa_clean', 'pert_iname'});
    ds = annotate_ds(ds, siginfo_path, 'fieldnames', {'moa_clean', 'pert_iname'});
    
    if ~isstruct(gpset)
       gpset = parse_geneset(gpset);
    end
    
    ds_info = gctmeta(ds);

    tab = struct2table(ds_info);

    [~, ord] = sortrows(tab, 'moa_clean');
    ds = ds_order(ds, 'column', ord);
    ds = ds_order(ds, 'row', ord);
    
    ds_info = gctmeta(ds);
    %[~, gp_smp, gpidx_smp, ~, ~] = get_groupvar(ds_info, {'moa_clean'}, {'moa_clean'});
    
    ngps = numel(gpset);

    dist_mat = 100 - ds.mat;
    dist_mat(logical(eye(size(dist_mat)))) = 0;
    
    rpt = struct();
    curr = 1;
    silhouette_mat = [];
    rids = [];
    for ii = 1:ngps     %moa
        %moa_a_idx = find(gpidx_smp == i);
        moa_a_idx = find(ismember({ds_info.(args.match_field)}, gpset(ii).entry));
        a_i = nan(numel(moa_a_idx),1);
        b_i = nan(numel(moa_a_idx),ngps);
        s_i = nan(numel(moa_a_idx), ngps);

        for jj = 1:numel(moa_a_idx)
            if numel(moa_a_idx) == 1
                a_i(jj) = 0;
            else
                a_i(jj) = ( 1 / (numel(moa_a_idx) - 1)) * sum(dist_mat(moa_a_idx(jj), moa_a_idx));
            end    
            for kk = 1:ngps
                if kk == ii
                    rpt(curr).pert_name = ds_info(moa_a_idx(jj)).pert_iname;
                    rpt(curr).pert_moa = ds_info(moa_a_idx(jj)).moa_clean;
                    rpt(curr).pert_moa_size = numel(moa_a_idx);
                    rpt(curr).moa_compare = gpset(kk).head;
                    rpt(curr).moa_compare_size = gpset(kk).len;
                    rpt(curr).a_i = a_i(jj);
                    rpt(curr).b_i = nan;
                    rpt(curr).s_i = nan;
                else            
                    if numel(moa_a_idx) == 1
                        b_i(jj, kk) = 0;
                        s_i(jj, kk) = 0;
                    else
                        b_i(jj, kk) = (1 / (gpset(kk).len)) * sum(dist_mat(moa_a_idx(jj), ismember({ds_info.(args.match_field)}, gpset(kk).entry)));
                        s_i(jj, kk) = ((b_i(jj, kk)) - a_i(jj))/ (max(b_i(jj, kk), a_i(jj)));  
                    end  

                    %s_i(jj, kk) = ((b_i(jj, kk)) - a_i(jj))/ (max(b_i(jj, kk), a_i(jj)));  

                    rpt(curr).pert_name = ds_info(moa_a_idx(jj)).pert_iname;
                    rpt(curr).pert_moa = ds_info(moa_a_idx(jj)).moa_clean;
                    rpt(curr).pert_moa_size = numel(moa_a_idx);
                    rpt(curr).moa_compare = gpset(kk).head;
                    rpt(curr).moa_compare_size = gpset(kk).len;
                    rpt(curr).a_i = nan;
                    rpt(curr).b_i = b_i(jj, kk);
                    rpt(curr).s_i = s_i(jj, kk);
                end
                curr = curr + 1;
            end
            %s_i(jj) = (min(b_i(jj, :)) - a_i(jj))/ (max(min(b_i(jj, :)), a_i(jj)));  
        end
        
        silhouette_mat = [silhouette_mat; s_i];
        ids = {ds_info(moa_a_idx).cid}';
        rids = [rids; ids];
    end

    sil_gct = mkgctstruct(silhouette_mat, 'rid', rids, 'cid', {gpset.head});
    
    tab = struct2table(rpt);
    [~,ord] = sortrows(tab, {'pert_moa', 'moa_compare', 'pert_name'});

    rpt = rpt(ord);

end

