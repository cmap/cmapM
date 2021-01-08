function [nes_obs_ds, qval_ds] = normalizeQueryWithPermutedNull(es_ds, score_ds, rank_ds, set_sizes, varargin)
% Compute null distributions using size-matched set permutations
% num_freq_sets sets to include based on frequency
% num_binned_sets sets to include by histogram binning

pnames = {'--num_perm'; '--num_freq_sets'; '--num_binned_sets'};
dflts = {1000; 25; 25};
help_str = {'Number of permutation per set-size';...
        'Number of sets to include based on frequency';...
        'Number sets to include by histogram binning'};
config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Compute null distributions using size-matched set permutations');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

[set_size_forperm, set_size_gpidx] = mortar.compute.Gutc.discretizeSetSizes(set_sizes, args.num_freq_sets, args.num_binned_sets);
num_sets_forperm = length(set_size_forperm);

% Normalized observed ES
nes_obs_ds = es_ds;
% FDR qvalues
qval_ds = es_ds;

%nes_obs_ds = ds_add_meta(nes_obs_ds, 'row', 'raw_es', num2cell(es_ds.mat));
%nes_obs_ds.cid = {'norm_es'};
[max_rank, ncol] = size(rank_ds.mat);

% Normalized null ES
nes_null = nan(args.num_perm, num_sets_forperm);


% weighted enrichment statistic, classic = false
is_weighted = true;
for icol = 1:ncol
    dbg(1, '%d/%d Processing %s', icol, ncol, nes_obs_ds.cid{icol});
    
    dbg(1, 'Computing permuted null distributions for %d sizes', num_sets_forperm);
    for ii=1:num_sets_forperm
        dbg(1, '%d/%d Null set_size %d, nperm:%d', ii, num_sets_forperm, set_size_forperm(ii), args.num_perm);
        this_idx = set_size_gpidx == ii;
        
        % Permuted size-matched rank and score matrices
        srt_rank = nan(set_size_forperm(ii), args.num_perm);
        srt_wt = nan(set_size_forperm(ii), args.num_perm);
        for jj=1:args.num_perm
            % sorted ranks sampled from 1:MAX_RANK
            srt_rank(:, jj) = sort(randsample(max_rank, set_size_forperm(ii)));
            % corresponding scores
            srt_wt(:, jj) = score_ds.mat(srt_rank(:, jj), icol);
        end
        
        % Compute enrichment statistic for nulls
        [es_null, es_running, rank_max, leadf] = ...
            mortar.compute.Connectivity.fastESCore(srt_rank, max_rank, is_weighted, srt_wt);
        % ignore NaNs arising from zero wts
        es_null = nan_to_val(es_null, 0);
        
        % Signed means of the Null ES distribution
        is_pos = es_null > 0;
        is_neg = es_null < 0;
        mu_pos = mean(es_null(is_pos));
        mu_neg = mean(es_null(is_neg));
        
        % Normalize null scores
        nes_null(is_pos, ii) = es_null(is_pos) / abs(mu_pos);
        nes_null(is_neg, ii) = es_null(is_neg) / abs(mu_neg);
        
        % Normalize observed scores
        % ignore NaNs
        es_obs = nan_to_val(nes_obs_ds.mat(this_idx, icol), 0);
        is_pos_obs = es_obs>0;
        is_neg_obs = es_obs<0;
        es_obs(is_pos_obs) = es_obs(is_pos_obs) / abs(mu_pos);
        es_obs(is_neg_obs) = es_obs(is_neg_obs) / abs(mu_neg);
        nes_obs_ds.mat(this_idx, icol) = es_obs;
        
    end
    % compute FDR
    x = nes_null(:);
    y = nes_obs_ds.mat(:, icol);
    nes_all = [x; y];
    is_null = [true(size(x)); false(size(y))];
    apply_null_adjust = true;
    apply_smooth = true;
    [qval, num, denom] = mortar.compute.Gutc.computeFDRGsea(nes_all, is_null, [], apply_null_adjust, apply_smooth);
    qval_ds.mat(:, icol) = qval(~is_null);
    %fdr_q_nlog10 = -log10(qval(~is_null) + eps);
    %nes_obs_ds = ds_add_meta(nes_obs_ds, 'row', 'fdr_q_nlog10', num2cellstr(fdr_q_nlog10, 'precision', 4));
end
% sort obs matrix by NES of first col
[srt_val, srt_idx] = sort(nes_obs_ds.mat(:, 1), 'descend');
nes_obs_ds = ds_order(nes_obs_ds, 'column', srt_idx);

end