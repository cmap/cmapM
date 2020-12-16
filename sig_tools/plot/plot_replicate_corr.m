function [hf, ccstats] = plot_replicate_corr(cc, varargin)

pnames = {'ridx', 'metric', 'hist_type',...
    'group_by','color','name',...
    'title','showfig','type',...
    'labelrt'};
dflts = {[], 'spearman', 'relative_freq',...
    'pert_id', 'r','',...
    '',true, 'full',...
    ''};
args = parse_args(pnames, dflts, varargin{:});

if isfileexist(cc)
    cc = parse_gctx(cc);
end

% group by specified field
[group, gpid, gpidx, ~, gp_cnt] = get_groupvar(cc.cdesc, cc.chd, args.group_by);


% discard un-annotated samples and singletons
keep = setdiff(group, {'-666'});
if ~isempty(keep) && ~isequal(length(unique(group)), length(keep))
    [~, ~, cidx] = intersect(keep, group, 'stable');
    cc = ds_slice(cc, 'cidx', cidx);
    [group, gpid, gpidx, ~, gp_cnt] = get_groupvar(cc.cdesc, cc.chd, args.group_by);
elseif isempty(keep)
    group = {};
    gpid = {};
    gpidx = [];
    gp_cnt = [];    
end

ngp = length(gpid);
hf = [];
ccstats = [];
nrep = nnz(gp_cnt>1);
if nrep
    %% rep and non-rep correlations
    lut = -ones(size(cc.mat));
    mean_cc = zeros(ngp, 1);
    min_cc = zeros(ngp, 1);
    max_cc = zeros(ngp, 1);
    rep_q75 = zeros(ngp, 1);
    rep_q95 = zeros(ngp, 1);
    nonrep_q75 = zeros(ngp, 1);
    nonrep_q95 = zeros(ngp, 1);
    nonrep_max = zeros(ngp, 1);
    for ii=1:ngp
        idx = gpidx==ii;
        lut(idx, idx) = 1;
        r = cc.mat(idx, idx);
        if nnz(idx)>1
            rut = tri2vec(r, 1);
            mean_cc(ii) = mean(rut);
            min_cc(ii) = min(rut);
            max_cc(ii) = max(rut);
            rep_q75(ii) = prctile(rut, 75);
            rep_q95(ii) = prctile(rut, 95);
            
	    % non rep
	    if sum(~idx) > 0
                nonrep = cc.mat(idx, ~idx);
                nonrep_q75(ii) = prctile(nonrep(:), 75);
                nonrep_q95(ii) = prctile(nonrep(:), 95);
                nonrep_max(ii) = max(nonrep(:));
	    else %if there is one group (ngp==1) then there will be no non-replicates (this can occur in the case of baseline plates)
	        fprintf('plot_replicate_corr - no non replicates found, there will be no null distribution for the plots\n');
                nonrep_q75(ii) = NaN;
                nonrep_q95(ii) = NaN;
                nonrep_max(ii) = NaN;
            end
        end
    end
    switch lower(args.type)
        case 'full'            
            % keep the upper half
            lut = triu(lut, 1);
            repcc = cc.mat(lut>0);
            nullcc = cc.mat(lut<0);
            xl = 'Spearman CC';
        case 'q75'
            repcc = rep_q75;
            nullcc = nonrep_q75;
            xl = 'Spearman CC (75th quantiles)';
        case 'q95'
            repcc = rep_q95;
            nullcc = nonrep_q95;
            xl = 'Spearman CC (95th quantiles)';
        case 'max'
            repcc = max_cc;
            nullcc = nonrep_max;
            xl = 'Spearman CC (Max)';
        otherwise
            error('Unknown type: %s', args.type);
    end
    cleaned_group_by = strrep(args.group_by, ',', '_');
    ccstats = struct(cleaned_group_by, {gpid}, 'num_reps', {gp_cnt}, ...
        'max_cc', {max_cc}, 'min_cc', {min_cc}, 'mean_cc', {mean_cc},...
        'rep_q75', {rep_q75}, 'nonrep_q75', {nonrep_q75});
 
    %% plot replicate CC distributions
    if ~isnan(nullcc)
        [f1, x1] = ksdensity(nullcc, 'function', 'pdf', 'npoints', 100);
    else %there were no non-replicates to use for the nullcc, therefore cannot calculate the ECDF of these
        f1 = NaN;
	x1 = [NaN NaN];
    end
    [f2, x2] = ksdensity(repcc, 'function', 'pdf', 'npoints', 100);
    
    % convert to relative frequencies
    switch lower(args.hist_type)
        case 'relative_freq'
            f1 = f1 * (x1(2) - x1(1));
            f2 = f2 * (x2(2) - x2(1));
        case 'pdf'
        otherwise
            error('Unknown histogram type: %s', args.hist_type')
    end
    
    hf = myfigure(args.showfig);
    if ~isnan(x1) & ~isnan(f1)
        fill(x1, f1, 'b','facealpha', 0.7)
    end
    hold on
    fill(x2, f2, args.color ,'facealpha', 0.7)

    if ~isnan(x1) & ~isnan(f1)
        legend_entries = {'Non-replicate CC', 'Replicate CC'};
    else
        legend_entries = {'Replicate CC'};
    end

    hleg = legend(legend_entries, 'location', 'northwest');
    set(hleg, 'fontsize', 12);    
    xlabel(xl)
    ylabel(texify(args.hist_type))
    namefig('replicate_corr');
    xlim([-1 1])

    text_xpos = -0.9;
    cur_axis = axis;
    text_ypos = double((cur_axis(4) + cur_axis(3)) / 2.0);
    group_by_txt = strrep(args.group_by, '_', '\_');
    msg = {['group\_by:  ' group_by_txt]};
    if isnan(x1) & isnan(f1)
	msg(2:4) = {'Warning:  there is no null distribution of correlation',
	       'values b/c there were no non-replicates on these',
	       'plate(s) based on their content and the group\_by above'};
    end
    text(text_xpos, text_ypos, msg);

    if ~isempty(args.name)
        namefig(args.name);
    end
    
    if ~isempty(args.labelrt)
        ylabelrt(texify(args.labelrt), 'color', 'b', 'fontsize', 10);
    end
    
    title(sprintf('%s n=%d reps=%d', args.title, length(group), nrep))
else
    fprintf('No replicates found\n');
end
end
