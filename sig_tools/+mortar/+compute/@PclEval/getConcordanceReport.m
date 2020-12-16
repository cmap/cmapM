function [rpt, member_info] = getConcordanceReport(rankpt_ds, gpset, gp_field)
    % GET_CONCORDANCE_RPT Create concordance table
    is_external_gp = true;
    % annotate from dataset
    if ~isempty(rankpt_ds.chd)
        si = gctmeta(rankpt_ds);
    else
        error('Column Annotations not available in dataset')
    end

    gp = ds_get_meta(rankpt_ds, 'column', gp_field);

    ng = length(gpset);
    gpid = {gpset.head}';
    gpname = {gpset.desc}';
    % switch to group id if desc is empty
    if any(cellfun(@isempty, gpname))
        gpname = gpid;
    end
    gpsz = zeros(ng, 1);
    tot_len = sum([gpset.len]);
    si_idx = zeros(tot_len, 1);
    si_gp = cell(tot_len, 1);
    ctr = 0;
    for ii=1:ng
        % column indices in rankpt_ds for this set
        gpidx = find(ismember(gp, gpset(ii).entry));
        if (length(gpidx) < gpset(ii).len)
            warning('Some members not found for %s. Expected %d, found %d',...
                gpid{ii}, gpset(ii).len, length(gpidx));
        end
        % Requires that there are no duplicates
        % gplen = min(length(gpidx), gpset(ii).len);
        gplen = length(gpidx);
        gpsz(ii) = gplen;
        this_idx = ctr + (1:numel(gpidx));
        % vector of column indices for all sets
        si_idx(this_idx) = gpidx;
        si_gp(this_idx) = gpid(ii);
        gpset(ii).gpidx = gpidx;
        ctr = ctr + gplen;
    end

    si_idx = si_idx(1:ctr);
    si_gp = si_gp(1:ctr);
    member_info = si(si_idx);
    [member_info.group_id] = si_gp{:};

    ngp = length(gpid);
    rpt = struct('group_id', gpid,...
        'group_name', gpname,...
        'pert_id', '',...
        'pert_iname', '',...
        'cell_id', '',...
        'pert_type', '',...
        'group_size', num2cell(gpsz),...
        'median_rankpt', nan,...
        'iqr_rankpt', nan,...
        'q75_rankpt', nan,...
        'q25_rankpt', nan,...
        'noutlier', 0,...
        'outlier', '',...
        'sig_id', '',...
        'pw_rankpt', '',...
        'row_rankpt', '');

    % connectivity stats for each member
    member_rankpt = zeros(size(si_idx));
    offset = 0;
    for ig = 1:ngp
        this_idx = gpset(ig).gpidx;
        nthis = nnz(this_idx);
        if nthis>0
            pert_id = print_dlm_line(getMeta(si(this_idx), 'pert_id'), 'dlm', '|');
            % TOREMOVE:temp fix for empty pert_iname
            %     pin = {si(this_idx).pert_iname};
            %     pin(cellfun(@isempty, pin)) = {''};
            pert_iname = print_dlm_line(getMeta(si(this_idx), 'pert_iname'), 'dlm', '|');
            cell_id = print_dlm_line(unique(getMeta(si(this_idx), 'cell_id')), 'dlm', '|');
            pert_type = print_dlm_line(unique(getMeta(si(this_idx), 'pert_type')), 'dlm', '|');
            pw = rankpt_ds.mat(this_idx, this_idx);
            pw(pw<-100) = nan;
            rpt(ig).pw_rankpt = pw;

            % set diagonal to NaN for stats
            pw(1:nthis+1:nthis*nthis) = nan;
            row_rankpt = nanmedian(pw, 2);
            stats = describe(row_rankpt);
            dbg(1, '%d/%d %s sz:%d med:%2.1f iqr:%2.1f', ig, ngp, gpid{ig}, ...
                gpsz(ig), stats.median, stats.iqr);

            rpt(ig).pert_id = pert_id;
            rpt(ig).pert_iname = pert_iname;
            rpt(ig).cell_id = cell_id;
            rpt(ig).pert_type = pert_type;
            rpt(ig).median_rankpt = stats.median;
            rpt(ig).iqr_rankpt = stats.iqr;
            rpt(ig).q75_rankpt = stats.q75;
            rpt(ig).q25_rankpt = stats.q25;
            rpt(ig).row_rankpt = row_rankpt;
            rpt(ig).sig_id = rankpt_ds.cid(this_idx);
            isoutlier = row_rankpt < (stats.q25 - 1.5*stats.iqr) |...
                row_rankpt > (stats.q75 + 1.5*stats.iqr);
            noutlier = nnz(isoutlier);
            if noutlier
                rpt(ig).noutlier = noutlier;
                rpt(ig).outlier = rankpt_ds.cid(this_idx(isoutlier));
            end

            member_rankpt(offset+(1:nthis)) = row_rankpt;
            offset = offset + nthis;
        end
    end
    % delete missing records
    %rpt = rpt([rpt.group_size]>0);

    % sort report by median rankpt
    val = [rpt.median_rankpt]';
    val(isnan(val)) = 0;
    [~, ord] = sort(val, 'descend');
    rpt = rpt(ord);

    if is_external_gp
        % handles non-mutually exclusive groups.
        % note this changes the ordering of si    
        if ~isempty(member_info)
            sz_lut = mortar.containers.Dict({rpt.group_id}', [rpt.group_size]');
            group_size = num2cell(sz_lut({member_info.group_id}'));
            [member_info.group_size] = group_size{:};

            member_rankpt_cell = num2cell(member_rankpt);
            [member_info.rank_pt] = member_rankpt_cell{:};
        end
    else

    end
end

function m = getMeta(si, field)
    if isfield(si, field)
        m = {si.(field)};
    else
        m = cell(length(si), 1);
        m(:) = {''};
    end
end