function res = runAnalysis(varargin)
% MarkerSelection.runAnalysis Select differentially expressed features.
% Type runAnalysis('-h') for help

% TODO
% p-values
% volcano plots
% Also see: LPE and SAM methods

[args, help_flag] = getArgs(varargin{:});
if ~help_flag
    res = struct('args', args,...
        'sig', [],...
        'full_score', [],...
        'up_set', [],...
        'dn_set', [],...
        'stats', []);
    res.args = args;
    % read inputs
    [ds, cl] = getInput(args);
    % run marker selection
    [res.sig, res.full_score, res.up_set, res.dn_set, res.stats] =...
        makeSignatures(ds, cl, args);
end

end

function [res, score_ds, up_set, dn_set, stats] = makeSignatures(ds, cl, args)
% Generate signatures for each pair of comparisons

[sig_gp, sig_idx] = getcls({cl.sig_id});
nsig = length(sig_gp);
res = struct('sig_id', sig_gp,...
    'phenotype', '',...
    'score_ds', '',...
    'marker_ds', '',...
    'stats', '');

dbg(1, 'Generating %d signatures...', nsig);
for ii=1:nsig
    dbg(1, '%d/%d %s', ii, nsig, sig_gp{ii})
    this_sig = sig_idx == ii;
    this_ds = ds_slice(ds, 'cid', {cl(this_sig).sample_id});
    this_cl = cl(this_sig);
    res(ii).phenotype = this_cl;
    [this_score, ds_cid] = twoClassCompare(this_ds, this_cl, args);
    %     perm_p = getPermutedPValue(ds, cl, 100, this_score, args);
    %     this_score = ds_add_meta(this_score, 'row', 'perm_p_value', num2cell(perm_p));
    res(ii).score_ds = this_score;
    res(ii).marker_ds = getTopnMarkers(this_ds, this_score, this_cl, args.nmarker, ds_cid);
    this_stats = getStats(res(ii).score_ds, res(ii).marker_ds, args);
    res(ii).stats = this_stats;    
    % remove metrics from row annotations, before merge
    this_score = ds_delete_meta(this_score, 'row', setdiff(this_score.rhd, this_ds.rhd, 'stable'));
    if ii>1
        score_ds = merge_two(score_ds, this_score, false);
        stats = [stats; this_stats];
    else
        score_ds = this_score;
        stats = this_stats;
    end
end

[up_set, dn_set] = get_genesets(score_ds, args.nmarker, 'descend');

end

function stats = getStats(score_ds, marker_ds, args)

fn = {'cid', 'metric', 'num_a', 'num_b', 'class_a', 'class_b'};
stats = keepfield(gctmeta(score_ds), fn);
row_meta = gctmeta(marker_ds,'row');
score = [row_meta.score]';
% signature strength
ss = mean(score(1:args.nmarker)) - mean(score(end-args.nmarker+1:end));
% number of features with lfc >= 1
lfc_ge1 = nnz(abs(ds_get_meta(score_ds, 'row', 'lfc'))>=1);
stats.strength = ss;
stats.num_fc_ge2 = lfc_ge1;

end

function perm_p = getPermutedPValue(ds, cl, nperm, score_ds, args)

nsample = length(ds.cid);
r = rand(nsample, nperm);
[~, iperm] = sort(r);
class_id = {cl.class_id}';
perm_cl = cl;
perm_mat = zeros(size(score_ds.mat, 1), nperm);
for ii=1:nperm
    this_class_id = class_id(iperm(:,ii));
    [perm_cl.class_id] = this_class_id{:};
    [perm_cl.sig_id] = deal(num2str(ii));
    this_score = twoClassCompare(ds, perm_cl, args);
    perm_mat(:, ii) = this_score.mat;
end

sign_score = sign(score_ds.mat);
sign_perm = bsxfun(@times, perm_mat, sign_score);
perm_p = sum(bsxfun(@gt, sign_perm, score_ds.mat), 2) / nperm;

end

function [score_ds, column_order] = twoClassCompare(ds, cl, args)
% Driver for class comparison
switch(lower(args.metric))
    case 's2n'
        [score_ds, column_order] = computeS2N(ds, cl, 's2n', args.fix_low_var, args.min_sample_size);
    case 's2n_robust'
        [score_ds, column_order] = computeS2N(ds, cl, 's2n_robust', args.fix_low_var, args.min_sample_size);
    otherwise
        error('Unsupported metric: %s', args.metric);
end
end

function marker_ds = getTopnMarkers(ds, score_ds, pheno, n, ds_cid)
% Select the top and bottom N markers
ridx = select_tail(size(ds.mat, 1), n);
marker_ds = ds_slice(ds, 'rid', score_ds.rid(ridx),...
    'cid', ds_cid);
% store the meta data fields
marker_ds = ds_add_meta(marker_ds, 'row', {'score'},...
    num2cell(score_ds.mat(ridx, 1)));
row_meta = gctmeta(ds_slice(score_ds, 'ridx', ridx), 'row');
marker_ds = annotate_ds(marker_ds, row_meta, 'dim', 'row');

marker_ds = annotate_ds(marker_ds, pheno, 'dim', 'column',...
    'keyfield', 'sample_id');
end

function [ds, cl] = getInput(args)
cl = parse_tbl(args.phenotype, 'outfmt', 'record');

assert(all(isfield(cl,{'sample_id', 'class_id', 'sig_id'})),...
    'Invalid class file');

cid = unique({cl.sample_id}, 'stable');
ds = parse_gctx(args.ds, 'cid', cid);

% transform to log2 if needed
if ~args.islog2
    ds.mat = safelog2(ds.mat);
end

end

function [mu, sigma] = getMeanStd(x, isrobust)
% Returns mean and stdev of rows of matrix X
% if isrobust is true returns median and MAD of X
if isrobust
    mu = median(x, 2);
    sigma = 1.4826 * mad(x, 1, 2);
else
    mu = mean(x, 2);
    sigma = std(x, 0, 2);
end
end

function [score_ds, cid_order] = computeS2N(ds, cl, metric, fix_low_var, min_sample_size)
% S2N compute signal to noise statistic.
% Note: Assumes ds.cid and cl.cid are in the same order
isrobust = strcmpi('s2n_robust', metric);
[class_id, clidx] = getcls({cl.class_id});
clcnt = accumarray(clidx, ones(size(clidx)));

assert(all(clcnt >= min_sample_size),...
    '%s: Each class should have atleast %d samples',...
    cl(1).sig_id, min_sample_size);
assert(isequal(length(clcnt),2),...
    '%s: Exactly two classes must be specified', cl(1).sig_id);

[~, srtidx] = sort(class_id);
nr = size(ds.mat, 1);
c0 = clidx==srtidx(2);
n0 = nnz(c0);
c0exp = ds.mat(:, c0);
n1 = nnz(~c0);
c1exp = ds.mat(:, ~c0);

[c0mu, c0sigma] = getMeanStd(c0exp, isrobust);
[c1mu, c1sigma] = getMeanStd(c1exp, isrobust);

if fix_low_var
    c0sigma = adjustLowSigma(c0sigma, n0, 'relative2mean', 0.025, 0.025, c0mu);
    c1sigma = adjustLowSigma(c1sigma, n0, 'relative2mean', 0.025, 0.025, c1mu);
end

% signal to noise
sn = (c1mu - c0mu)./(c1sigma + c0sigma);
% sn = (c1mu - c0mu)./min(c1sigma, c0sigma);

% fold change in a linear scale
fc = pow2(c1mu - c0mu);
% log fold change
lfc = log2(fc);

rnk = rankorder(sn, 'direc', 'descend', 'fixties', false);
score_ds = mkgctstruct(sn, 'rid', ds.rid, 'rhd', ds.rhd,...
    'rdesc', ds.rdesc, 'cid', {cl(1).sig_id});
metric_str = metric;

% row annotations
row_key = {'rank', 'num_a', 'num_b',...
    'mean_a', 'mean_b','std_a',...
    'std_b', 'fc', 'lfc'};
row_val = num2cell([rnk, ones(nr,1)*n1, ones(nr,1)*n0,...
    c1mu, c0mu, c1sigma,...
    c0sigma, fc, lfc]);
score_ds = ds_add_meta(score_ds, 'row', row_key, row_val);

% column annotations
c0_first = find(c0, 1, 'first');
c1_first = find(~c0, 1, 'first');
if isfield(cl, 'class_label')
    class_a_str = cl(c1_first).class_label;
    class_b_str = cl(c0_first).class_label;
else
    class_a_str = cl(c1_first).class_id;
    class_b_str = cl(c0_first).class_id;
end
sample_a = {cl(~c0).sample_id}';
sample_b = {cl(c0).sample_id}';

col_key = {'metric', 'num_a',...
    'num_b', 'sample_a',...
    'sample_b', 'class_a',...
    'class_b'};
col_val = {metric_str, n0,...
    n1, sample_a,...
    sample_b, class_a_str,...
    class_b_str};
score_ds = ds_add_meta(score_ds, 'column', col_key, col_val);

% sort dataset by rank
[~, srtidx] = sort(rnk);
cid_order = {cl(~c0).sample_id,cl(c0).sample_id}';
score_ds = ds_slice(score_ds, 'ridx', srtidx);

end

function sigma = adjustLowSigma(sigma, n, method, min_sigma, frac_mu, mu)
% ADJUST_LOW_SIGMA Heuristics to handle low standard deviation in
% expression data.
%   ASIGMA = ADJUST_LOW_SIGMA(SIGMA, N, METHOD, MIN_SIGMA, FRAC_MU, MU)
%   adjusts SIGMA based on the selected METHOD.
%
% Valid choices for METHOD are:
% 'relative2mean' : for N<10 SIGMA must be >= max(MIN_SIGMA, FRAC_MU*MU)
%       For N>=10 SIGMA should be at least MIN_SIGMA
% 'fixed' : the SIGMA should be at least MIN_SIGMA

switch method
    case 'relative2mean'
        if n<10
            % small samples
            min_std = max(min_sigma, frac_mu*abs(mu));
            sigma = max(sigma, min_std);
        else
            sigma = max(sigma, min_sigma);
        end
    case 'fixed'
        sigma = max(sigma, min_sigma);
    otherwise
        error('Unknown adjustment : %s', method);
end
end

function [args, help_flag] = getArgs(varargin)
% validate inputs
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    assert(~isempty(args.ds), 'Dataset not specified');
    assert(~isempty(args.phenotype), 'Phenotype definition not specified');
end
end
