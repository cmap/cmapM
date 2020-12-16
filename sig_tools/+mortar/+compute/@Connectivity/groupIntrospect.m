function groupIntrospect(varargin)
end


function [rpt, si] = get_concordance_rpt(score_ds, rankpt_ds, rank_denom, args)
% GET_CONCORDANCE_RPT Create concordance table

is_external_gp = isfileexist(args.query_group{1});
    
if args.annotate_from_ds
    if args.use_cache
        % annotate from cache file
        [~, keep]=intersect_ord(score_ds.cid, rankpt_ds.cid);
        if ~isempty(score_ds.cdesc)
            si = cell2struct([score_ds.cid(keep), score_ds.cdesc(keep, :)]',...
                [{'sig_id'}; score_ds.chd]);
        else
            error('Annotation not available in dataset')
        end
    else
        % annotate from dataset
        [~, keep]=intersect_ord(args.rank.cid, rankpt_ds.cid);
        if ~isempty(args.rank.cdesc)
            si = cell2struct([args.rank.cid(keep), args.rank.cdesc(keep, :)]',...
                [{'sig_id'}; args.rank.chd]);
        elseif ~isempty(args.score.cdesc)
            si = cell2struct([args.score.cid(keep), args.score.cdesc(keep, :)]',...
                [{'sig_id'}; args.score.chd]);
        else
            error('Annotation not available in dataset')
        end
    end
else
    
    si_fields = {'sig_id', 'pert_id', 'pert_iname', 'cell_id',...
        'pert_type', 'pert_itime', 'pert_idose',...
        'is_gold', 'distil_cc_q75', 'distil_ss',...
        'pct_self_rank_q25', 'distil_nsample','pool_id', 'brew_prefix'};
    if ~is_external_gp
        si_fields = union(args.query_group, si_fields);
    end
        
    % get meta info from mongo
    si = sig_info(rankpt_ds.cid, 'fields', si_fields);
end

if is_external_gp
    gpset = parse_geneset(args.query_group{1});
    if strcmpi(args.ext_group_field, '_cid')
        gp = rankpt_ds.cid;
    else
        gp = {si.(args.ext_group_field)};
    end
    ng = length(gpset);
    gpid = {gpset.head}';
    gpsz = [gpset.len]';
    tot_len = sum(gpsz);
    si_idx = zeros(tot_len, 1);
    si_gp = cell(tot_len, 1);
    ctr = 0;
    for ii=1:ng        
        gpidx = find(ismember(gp, gpset(ii).entry));
        if ~isequal(length(gpidx), gpset(ii).len)
            warning('Some members not found for %s. Expected %d, found %d',...
                    gpid{ii}, gpset(ii).len, length(gpidx));            
        end
        gplen = min(length(gpidx), gpset(ii).len);
        this_idx = ctr + (1:gplen);
        si_idx(this_idx) = gpidx;
        si_gp(this_idx) = gpid(ii); 
        gpset(ii).gpidx = gpidx;
        ctr = ctr + gplen;
    end
else
    if strcmpi(args.ext_group_field, '_cid')
        gp = rankpt_ds.cid;
        [gpid, gpidx] = getcls(gp);
        gpsz = accumarray(nl, ones(size(nl)));
    else
        [gp, gpid, gpidx, ~, gpsz] = get_groupvar(si, fieldnames(si), args.query_group);
        [si.group_id] = gp{:};
    end
end

ngp = length(gpid);
rpt = struct('group_id', gpid,...
    'pert_id', '',...
    'pert_iname', '',...
    'cell_id', '',...
    'pert_type', '',...
    'pert_idose', '',...
    'pert_itime', '',...
    'group_size', num2cell(gpsz),...
    'median_rankpt', '',...
    'iqr_rankpt', '',...
    'q75_rankpt', '',...
    'q25_rankpt', '',...
    'noutlier', 0,...
    'outlier', '',...
    'rank_denom', rank_denom,...
    'sig_id', '',...
    'pw_rankpt', '',...
    'row_rankpt', '');

for ig = 1:ngp
    if is_external_gp
        this_idx = gpset(ig).gpidx;
    else
        this_idx = find(gpidx == ig);
    end    
    
    nthis = nnz(this_idx);
    pert_id = print_dlm_line({si(this_idx).pert_id}, 'dlm', '|');
    % TOREMOVE:temp fix for empty pert_iname
    pin = {si(this_idx).pert_iname};
    pin(cellfun(@isempty, pin)) = {''};
    pert_iname = print_dlm_line(unique(pin, 'stable'), 'dlm', '|');    
    cell_id = print_dlm_line(unique({si(this_idx).cell_id}, 'stable'), 'dlm', '|');
    pert_idose = print_dlm_line(unique({si(this_idx).pert_idose}, 'stable'), 'dlm', '|');
    pert_itime = print_dlm_line(unique({si(this_idx).pert_itime}, 'stable'), 'dlm', '|');
    pert_type = print_dlm_line(unique({si(this_idx).pert_type}, 'stable'), 'dlm', '|');
    pw = rankpt_ds.mat(this_idx, this_idx);
    pw(pw<-100) = nan;
    rpt(ig).pw_rankpt = pw;
    
    pw(logical(eye(nthis))) = nan;
    row_rankpt = nanmedian(pw, 2);
    stats = describe(row_rankpt);
    rpt(ig).pert_id = pert_id;
    rpt(ig).pert_iname = pert_iname;
    rpt(ig).cell_id = cell_id;
    rpt(ig).pert_idose = pert_idose;
    rpt(ig).pert_itime = pert_itime;
    rpt(ig).pert_type = pert_type;
    rpt(ig).median_rankpt = stats.median;
    rpt(ig).iqr_rankpt = stats.iqr;
    rpt(ig).q75_rankpt = stats.q75;
    rpt(ig).q25_rankpt = stats.q25;
    rpt(ig).row_rankpt = row_rankpt;
    
    isoutlier = row_rankpt < (stats.q25 - 1.5*stats.iqr);
    noutlier = nnz(isoutlier);
    if noutlier
        rpt(ig).noutlier = noutlier;
        rpt(ig).outlier = rankpt_ds.cid(this_idx(isoutlier));
    end
    rpt(ig).sig_id = rankpt_ds.cid(this_idx);
end

if is_external_gp
    % handles non-mutually exclusive groups.
    % note this changes the ordering of si
    si = si(si_idx);
    [si.group_id] = si_gp{:};    
else
    
end
end

function plot_pwheatmap(rpt, args)
% PLOT_PWHEATMAP create pw heatmap

for ii=1:length(rpt)
    nx = size(rpt(ii).pw_rankpt, 1);
    if nx > 1
        myfigure(false);
        x = rpt(ii).pw_rankpt;
        x(isnan(x)) = 0;
        if args.pw_sort
            %         % re-order matrix based on hclust
            %         y = pdist(x, 'correlation');
            %         z = linkage(y, 'average');
            %         [h, t, ord] = dendrogram(z, 0);

            % re-order matrix based on median rankpt
            [~, ord] = sort(median(x),'descend');
        else
            ord = (1:size(x, 1))';
        end
        if isfield(rpt(ii), args.pw_label_field)
            lbl = tokenize(rpt(ii).(args.pw_label_field), '|');
%             lbl = rpt(ii).(args.pw_label_field);
            lbl = lbl(ord);
        else
            lbl = rpt(ii).sig_id(ord);        
        end
        
        short_lbl = strtrunc(lbl, 25);
        imagesc(x(ord, ord))
        colormap(rankpointmap80);
        axis square
        grid off
        colorbar
        set(gca, 'fontsize', 6);
        if nx <= 40            
            set(gca, 'xtick', 1:length(x), 'xticklabel', short_lbl);
            set(gca, 'ytick', 1:length(x), 'yticklabel', short_lbl);
            rotateticklabel(gca, 45);
        else
            % only show outliers
            if rpt(ii).noutlier
                keep_idx = find(ismember(lbl, rpt(ii).outlier));
                if ~isempty(keep_idx)
                    set(gca, 'xtick', keep_idx, 'xticklabel', short_lbl(keep_idx));
                    set(gca, 'ytick', keep_idx, 'yticklabel', short_lbl(keep_idx));
                    rotateticklabel(gca, 45);
                end
            end
        end        
        caxis ([-100 100])
        title_str = strtrunc(sprintf('%s|%s', rpt(ii).group_id, rpt(ii).pert_iname), 40);
        title(texify(sprintf('%s (n=%d)', title_str, nx)),...
              'fontsize', 10);
        outname = lower(validvar(sprintf('heatmap_%s', rpt(ii).group_id), '_'));
        namefig(outname{1});
    end
end

end

function plot_summary(rpt)
% PLOT_SUMMARY Generate boxplot input

ngp = length(rpt);
[~, ord] = sort([rpt.median_rankpt], 'descend');
group_order = {rpt(ord).group_id};

nel = sum([rpt.group_size]);
x = zeros(nel, 1);
group_id = cell(nel, 1);
pert_iname = cell(nel, 1);
group_size = zeros(nel, 1);
ctr = 0;

for ii=1:ngp
    this = ord(ii);
    this_sz = rpt(this).group_size;
    x(ctr+(1:this_sz)) = rpt(this).row_rankpt;
    group_id(ctr+(1:this_sz)) = {rpt(this).group_id};
    pert_iname(ctr+(1:this_sz)) = {rpt(this).pert_iname};
    group_size(ctr+(1:this_sz)) = rpt(this).group_size;
    ctr = ctr + this_sz;
end

%% Create boxplot
myfigure(false);
gp = [group_id, pert_iname, num2cellstr(group_size)]';
gplbl = strtrunc(tokenize(sprintf('%s|%s (%s)#', gp{:}),'#'),25);
% reference line at 90 rankpoints
plot_constant(90, false, 'color', get_color('ochre'),...
              'linewidth', 1.5, 'linestyle', '--');
hold on
for ii=1:ngp
    pts = rpt(ord(ii)).row_rankpt;
    isoutlier = pts < rpt(ord(ii)).q25_rankpt - 1.5*rpt(ord(ii)).iqr_rankpt;
    
    plot(pts(isoutlier), ii+0.05*randn(nnz(isoutlier), 1), '+',...
        'color', get_color('scarlet'), 'markersize', 4);
    plot(pts(~isoutlier), ii+0.05*randn(nnz(~isoutlier), 1), 'x',...
        'color', get_color('azure'), 'markersize', 4);
    
end
boxplot_opt = {'orientation', 'horizontal', 'symbol', ''};
if ngp>50
    boxplot_opt = [boxplot_opt, {'plotstyle', 'compact'}];
end
bh = boxplot(x, gplbl(1:end-1), boxplot_opt{:});
xlim([-100 100])
axis xy
boxparent = getappdata(gca, 'boxplothandle');

% handles of box plots
% dh = getappdata(boxparent,'datahandles');
% whiskers are black
set(findobj(gca,'tag', 'Whisker'), 'color', get_color('grey'));
% boxes are forest
set(findobj(gca,'tag', 'Box'), 'color', get_color('forest'), 'linewidth', 1.5);
% medians are scarlet
% for standard boxplots
set(findobj(gca, 'tag', 'Median'),...
    'color', get_color('scarlet'), 'linewidth', 1.5);
% for compact style boxplots
set(findobj(gca, 'tag', 'MedianOuter'),...
    'Marker', 'o',...
    'MarkerFaceColor', get_color('scarlet'),...
    'MarkerEdgeColor', get_color('black'))
set(findobj(gca, 'tag', 'MedianInner'),...
    'Marker', '.',...
    'MarkerEdgeColor', get_color('scarlet'))

th = getappdata(boxparent, 'labelhandles');
set(th,'horizontalalignment', 'right', 'units','normalized',...
    'fontsize', 8, 'fontweight', 'normal');
nt = length(th);
norm_offset = -0.01;
for ii=1:nt
    pos = get(th(ii), 'position');
    set(th(ii), 'position', [norm_offset, pos(2:end)], 'fontweight', 'bold');
end
lh = getappdata(boxparent, 'boxlisteners');
for ii=1:length(lh)
    delete(lh{ii});
end
axpos=get(gca,'position');
set(gca, 'position', [0.35, axpos(2), 0.5, axpos(end)],...
    'xtick', sort([90, linspace(-100, 100, 9)]), 'fontsize', 11);
title('Concordance of groups', 'fontsize', 12);
xlabel(sprintf('Rank Point (denom:%d)', rpt(1).rank_denom));
namefig('boxplot_rankpt');
end