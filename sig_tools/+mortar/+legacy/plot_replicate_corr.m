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
group = cc.cdesc(:, cc.cdict(args.group_by));
[gpid, gpidx] = getcls(group);
gp_cnt = accumarray(gpidx, ones(size(gpidx)));

% discard un-annotated samples and singletons
% keep = setdiff(group, [{'-666'}; gpid(gp_cnt==1)]);
keep = setdiff(group, {'-666'});
if ~isequal(length(unique(group)), length(keep))
    [~, ~, cidx] = map_ord(keep, group);
    cc = gctextract_tool(cc, 'cidx', cidx);
    group = cc.cdesc(:, cc.cdict(args.group_by));
    [gpid, gpidx] = getcls(group);
    gp_cnt = accumarray(gpidx, ones(size(gpidx)));
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
            nonrep = cc.mat(idx, ~idx);
            nonrep_q75(ii) = prctile(nonrep(:), 75);
            nonrep_q95(ii) = prctile(nonrep(:), 95);
            nonrep_max(ii) = max(nonrep(:));
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
    ccstats = struct(args.group_by, {gpid}, 'num_reps', {gp_cnt}, ...
        'max_cc', {max_cc}, 'min_cc', {min_cc}, 'mean_cc', {mean_cc},...
        'rep_q75', {rep_q75}, 'nonrep_q75', {nonrep_q75});
 
    %% plot replicate CC distributions
    [f1, x1] = ksdensity(nullcc, 'function', 'pdf', 'npoints', 100);
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
    fill(x1, f1, 'b','facealpha', 0.7)
    hold on
    fill(x2, f2, args.color ,'facealpha', 0.7)
    hleg = legend('Non-replicate CC', 'Replicate CC','location','northwest');
    set(hleg, 'fontsize', 12);    
    xlabel(xl)
    ylabel(texify(args.hist_type))
    namefig('replicate_corr');
    xlim([-1 1])
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