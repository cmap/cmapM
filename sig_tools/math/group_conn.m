function stats = group_conn(cc, group_by, varargin)
% pnames = {'metric'};
% dflts = {'spearman'};
% args = parse_args(pnames, dflts, varargin{:});
% gctwriter = get_gctwriter(args.use_gctx);
% 
% figdir = mkworkfolder(wkdir, 'figures', ...
%     'forcesuffix', false, 'overwrite', true);

cc = parse_gctx(cc);

% [gpvar, gp, gpidx] = get_groupvar(ds.cdesc, ds.chd, group_by);
[gp, gpidx] = getcls(group_by);
ninstance = size(cc.mat, 1);
rnk = rankorder(cc.mat + diag(diag(cc.mat)*nan),...
    'direc', 'descend','fixties', false);
ngp = length(gp);
gpsz = accumarray(gpidx, ones(size(gpidx)));

%% Self connectivity stats
[~, gpselect] = unique(gpidx);
stats = struct('id', gp, ...
    'nreplicate', num2cell(gpsz),...
    'ninstance', ninstance,...
    'npair', -666,...
    'rank_min', -666,...
    'rank_max', -666,...
    'rank_q25', -666,...
    'rank_all', -666,...
    'cc_max', -666,...
    'cc_q75', -666,...
    'cc_all', -666);

for ii=1:ngp
    keep=gpidx==ii;
    this_cc = cc.mat(keep, keep);
    this_rnk = rnk(keep, keep);
    % ignore main diagonals
    this_rnk = this_rnk + diag(nan(size(this_rnk,1),1));
    % make the matrix symmetric by taking the min rank
    this_rnk = min(this_rnk,this_rnk');
    this_vec = this_rnk(:);
    s = describe(this_vec);
    all_rnk = tri2vec(this_rnk);
    [srt_rnk, srt_idx] = sort(all_rnk, 'ascend');
    all_cc = tri2vec(max(this_cc, this_cc'));

    if srt_idx > 0
        stats(ii).npair = length(srt_idx);
        stats(ii).rank_min = s.min;        
        stats(ii).rank_max = s.max;
        stats(ii).rank_q25 = s.fivenum(2);
        stats(ii).rank_all = print_dlm_line(srt_rnk, 'dlm', ',');
        stats(ii).cc_max = all_cc(srt_idx(1));
        stats(ii).cc_q75 = prctile(all_cc, 75);
        stats(ii).cc_all = print_dlm_line(all_cc(srt_idx), 'dlm', ',',...
            'precision', 2);
    end
end

% mktbl(fullfile(wkdir, 'self_connections.txt'), stats);