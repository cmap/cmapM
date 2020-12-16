function runAnalysis(varargin)
% Select differentially expressed features.

% Example: marker_selection_tool(expr_file, class_file)

% TODO
% add class ids
% order matrix so that its class_a class_b
% p-values
% volcano plots
% Also see: LPE and SAM methods
help_flag = false;

try    
    args = get_args(varargin{:});
    
catch ME
    if strcmp(ME.identifier, 'mortar:common:ArgParse:HelpRequest')
        help_flag = true;
    else
        error('%s %s', ME.identifier, ME.message);
    end
end

if ~help_flag
    wkdir = mktoolfolder(args.out, mfilename);
    print_args(mfilename, fullfile(wkdir, sprintf('%s_params.txt', mfilename)), args);
    
    % read inputs
    [ds, cl, prefix] = get_input(args);
    
    % run marker selection
    [score_ds, column_order] = two_class_compare(ds, cl, args);
    
    % get markers
    marker_ds = get_topn_markers(ds, score_ds, column_order, args.nmarker);
        
    % save the marker matrix
    marker_file = mkgct(fullfile(wkdir,...
                        sprintf('%s_%s_marker.gct', prefix, args.metric)),...
                        marker_ds);
    create_heatmap(marker_file, prefix, wkdir, args);

    % save the score matrix
    mkgct(fullfile(wkdir,...
                   sprintf('%s_%s_score.gct', prefix, args.metric)),...
                   score_ds);

end

end

function [score_ds, column_order] = two_class_compare(ds, cl, args)
% Driver for class comparison
    dbg(1, 'Using metric: %s', args.metric);
    switch(lower(args.metric))
        case 's2n'
            [score_ds, column_order] = compute_s2n(ds, cl, 's2n', args.fix_low_var);
        case 's2n_robust'
            [score_ds, column_order] = compute_s2n(ds, cl, 's2n_robust', args.fix_low_var);
        otherwise
            error('Unsupported metric: %s', args.metric);
    end
    
end

function create_heatmap(marker_file, prefix, wkdir, args)
mkheatmap(marker_file, fullfile(wkdir,...
                                sprintf('%s_%s_heatmap.png',...
                                prefix, args.metric)),...
          'row_text', {'Id', 'symbol', 'score',...
                       'lfc', 'mean_a', 'mean_b',...
                       'std_a', 'std_b'},...
          'column_color', {'class'},...
          'title', prefix);
end

function marker_ds = get_topn_markers(ds, score_ds, column_order, n)
% Select the top and bottom N markers
    ridx = select_tail(size(ds.mat, 1), n);
    marker_ds = ds_slice(ds, 'rid', score_ds.rid(ridx), 'cid', ds.cid(column_order));
    % store the meta data fields
    marker_ds = ds_add_meta(marker_ds, 'row', {'score'},...
        num2cell(score_ds.mat(ridx, 1)));
    marker_ds = ds_add_meta(marker_ds, 'row', score_ds.rhd,...
        score_ds.rdesc(ridx, :));    
end

function [ds, cl, prefix] = get_input(args)
cl = parse_tbl(args.class);
assert(all(ismember({'cid', 'class_id'}, fieldnames(cl))),...
    'Invalid class file');
% sync cids
ds = parse_gctx(args.ds, 'cid', cl.cid);

[cn, nl] = getcls(cl.class_id);
cnt = accumarray(nl, ones(size(nl)));
assert(all(cnt >= args.min_sample_size),...
       'Each class should have atleast %d samples');
assert(isequal(length(cnt),2),...
       'Exactly two classes must be specified');

% transform to log2 if needed
if ~args.islog2
    ds.mat = safelog2(ds.mat);
end

% get prefix
[~, prefix] = strip_dim(ds.src);

end

function [mu, sigma] = get_meanvar(x, isrobust)
% Compute mean and stdev of X, optionally robust variants
if isrobust
    mu = median(x, 2);
    sigma = 1.4826 * mad(x, 1, 2);
else
    mu = mean(x, 2);
    sigma = std(x, 0, 2);
end
end

function [score_ds, column_order] = compute_s2n(ds, cl, metric, fix_low_var)
% S2N compute signal to noise statistic.
% Note: Assumes ds.cid and cl.cid are in the same order

isrobust = strcmpi('s2n_robust', metric);
[class_id, clidx] = getcls(cl.class_id);
[~, srtidx] = sort(class_id);

nr = size(ds.mat, 1);
c0 = clidx==srtidx(2);
n0 = nnz(c0);
c0exp = ds.mat(:, c0);
n1 = nnz(~c0);
c1exp = ds.mat(:, ~c0);

[c0mu, c0sigma] = get_meanvar(c0exp, isrobust);
[c1mu, c1sigma] = get_meanvar(c1exp, isrobust);

if fix_low_var
    c0sigma = adjust_low_sigma(c0sigma, n0, 'relative2mean', 0.025, 0.025, c0mu);

    c1sigma = adjust_low_sigma(c1sigma, n0, 'relative2mean', 0.025, 0.025, c1mu);

end

% signal to noise
sn = (c1mu - c0mu)./(c1sigma + c0sigma);
% sn = (c1mu - c0mu)./min(c1sigma, c0sigma);

% fold change in a linear scale
fc = pow2(c1mu - c0mu);
lfc = log2(fc);
rnk = rankorder(sn, 'direc', 'descend', 'fixties', false);

score_ds = mkgctstruct(sn, 'rid', ds.rid, 'rhd', ds.rhd,...
                       'rdesc', ds.rdesc, 'cid', {'score'});
metric_str = {metric};
key = {'metric', 'rank', 'num_a',...
       'num_b', 'mean_a', 'mean_b',...
       'std_a', 'std_b', 'fc',...
       'lfc'};
val = [metric_str(ones(nr,1)),...
       num2cell([rnk, ones(nr,1)*n0, ones(nr,1)*n1,...
                 c0mu, c1mu, c0sigma,...
                 c1sigma, fc, lfc])];
score_ds = ds_add_meta(score_ds, 'row', key, val);

% sort dataset by rank
[~, srtidx] = sort(rnk);
score_ds = gctextract_tool(score_ds, 'ridx', srtidx);
column_order = [find(~c0); find(c0)];
end

function sigma = adjust_low_sigma(sigma, n, method, min_sigma, frac_mu, mu)
% ADJUST_LOW_SIGMA Heuristics to handle low standard deviation in
% expression data.
%   ASIGMA = ADJUST_LOW_SIGMA(SIGMA, N, METHOD, MIN_SIGMA, FRAC_MU, MU)
%   adjusts SIGMA based on the selected METHOD.
%
% Valid choices for METHOD are:
% 'relative2mean' : for N<10 SIGMA must be >= max(MIN_SIGMA, FRAC_MU*MU)
%       For N>=10 no adjustment except when SIGMA=0 when it is set to
%       MIN_SIGMA
% 'fixed' : the stdev should be at least MIN_SIGMA

switch method
    case 'relative2mean'
        if n<10
            % small samples
            min_std = max(min_sigma, frac_mu*abs(mu));
            sigma = max(sigma, min_std);
        elseif (sigma - 0) < eps
            sigma = min_sigma;            
        end
    case 'fixed'
        sigma = max(sigma, min_sigma);
    otherwise
        error('Unknown adjustment : %s', method);
end
end

function args = get_args(varargin)
% TODO
% validate inputs 
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'Two-class comparison', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
end

end
