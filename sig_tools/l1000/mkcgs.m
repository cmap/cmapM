function [cgs, cgs_annot] = mkcgs(score, annot, cgs_gp)
% Compute consensus signature.
%   MKGCS(SCORE, ANNOT, GROUP)

[cgs_id, cgs_idx] = getcls(cgs_gp);
gpsz = accumarray(cgs_idx, ones(size(cgs_idx)));

ncgs = length(cgs_id);
cgs_annot = struct('sig_id', cgs_id,...
                   'brew_prefix', '',...
                   'pert_id', '',...
                   'pert_iname', '',...
                   'cell_id', '',...
                   'pert_type', '',...
                   'pert_itime', '',...
                   'pert_idose', '',...
                   'distil_nsample', '',...
                   'distil_wt', '',...
                   'distil_cc_pw', '',...
                   'distil_ss', '',...
                   'distil_cc_q75', '',...
                   'distil_id', '',...
                   'distil_pert_id', '',...
                   'distil_nrep', '',...
                   'cgs_vs_sister_cc', '',...
                   'pool_id', '',...
                   'num_brew', '',... 
                   'target_is_lm', '',...
                   'target_is_bing', '',...
                   'target_zs', '',...
                   'target_rank_full', '',...
                   'target_rank_bing', '',...
                   'provenance_code','KMV+F2D+INO+QNO+ZSP+MOZ+GBP,D+CSM'...
                   );
                                  
%%
nr = size(score.mat, 1);
cgs_mat = zeros(nr, ncgs);

lm = parse_grp('/cmap/data/vdb/spaces/lm_epsilon_n978.grp');
[~, lmidx] = intersect_ord(score.rid, lm);

pert_id={annot.pert_id}';
isepsilon=strcmp('epsilon', {annot.pool_id}');
pool_id(isepsilon) = {'epsilon'};
pool_id(~isepsilon) = {'deltap'};
brew_id = {annot.brew_prefix}';

% tok = tokenize(cgs_gp, ':');
% cgs_cell_id = cellfun(@(x) x{1}, tok, 'uniformoutput', false);
% cgs_pert_time = cellfun(@(x) x{2}, tok, 'uniformoutput', false);
% cgs_pert_iname = cellfun(@(x) x{3}, tok, 'uniformoutput', false);
% cgs_pert_dose = cellfun(@(x) x{4}, tok, 'uniformoutput', false);

%% gene symbols
bing = parse_grp('/cmap/data/vdb/spaces/bing_n10638.grp');
[~, bing_idx] = intersect_ord(score.rid, bing);
gs = ps2genesym(score.rid);
isepsilon = islandmark(score.rid, 'epsilon');
isdeltap = islandmark(score.rid, 'deltap');
epsilon_dict = containers.Map(gs(isepsilon), find(isepsilon));
deltap_dict = containers.Map(gs(isdeltap), find(isdeltap));

t0 = tic;
for ii=1:ncgs
    if gpsz(ii)>1
        cidx = find(cgs_idx == ii);
        ubrew_id = unique(brew_id(cidx));
        upool_id = unique(pool_id(cidx));
        cgs_cell_id = annot(cidx(1)).cell_id;
        cgs_pert_itime = annot(cidx(1)).pert_itime;
        cgs_pert_iname = annot(cidx(1)).pert_iname;
        cgs_pert_idose = annot(cidx(1)).pert_idose;
        cgs_pert_type = strcat(annot(cidx(1)).pert_type,'.cgs');
        % filter multi-pool signatures
        if length(upool_id)>1
            [pool_gp, pool_idx] = getcls(pool_id(cidx));
            pool_sz = accumarray(pool_idx, ones(size(pool_idx)));
            if ~isequal(pool_sz(1), pool_sz(2))
                % keep pool with most hps
                [~, max_idx] = max(pool_sz);
                cidx = cidx(pool_idx==max_idx);
            else
                % pick epsilon
                pick = find(strcmp('epsilon', pool_gp));
                cidx = cidx(pool_idx==pick);
            end
            ubrew_id = unique(brew_id(cidx));
            upool_id = unique(pool_id(cidx));
        end
        
        %pert_ids
        pid = pert_id(cidx);
        % unique pert ids
        [upid, pidx]=getcls(pert_id(cidx));
        x = score.mat(:, cidx);
        num_sig = length(pid);
        num_sister = length(upid);
        
        % cc between reps
        cc = fastcorr(x(lmidx, :), 'type', 'spearman');
        % cc_q75 between reps
        cc_q75 = prctile(tri2vec(cc), 75);
        
        if ~isequal(num_sig, num_sister)
            % multiple signatures per hp, modz them first
            sz = accumarray(pidx, ones(size(pidx)));
            y = zeros(nr, num_sister);
            for jj=1:num_sister
                sidx = pidx == jj;
                [y(:, jj), norm_wt, cc] = modzs(x(:, sidx), lmidx,...
                    'clip_low_wt', true,...
                    'clip_low_cc', true, ...
                    'low_thresh_wt', 0.01, 'low_thresh_cc', 0,...
                    'metric', 'wt_avg');
            end
            x = y;
        end
        % modz sisters
        [czs, norm_wt, cc_clip] = modzs(x, lmidx,...
            'clip_low_wt', true,...
            'clip_low_cc', true, ...
            'low_thresh_wt', 0.01, 'low_thresh_cc', 0,...
            'metric', 'wt_avg');
        
        cgs_mat(:, ii) = czs;
        
        % if multiple pert_ids, report correlations between them
        if num_sister>1
            % cc between sisters
            cc = fastcorr(x(lmidx, :), 'type', 'spearman');
            % cc_q75 between sister hp's
            cc_q75 = prctile(tri2vec(cc), 75);
        end
        
        % correlation between cgs and sisters
        cgs_vs_sister_cc = fastcorr(czs(lmidx, :), x(lmidx, :), 'type', ...
            'spearman');
        % signal strength
        ss = sig_strength(czs, 'n', 100);
        
        % zscore and rank of target
        ridx = find(strcmp(cgs_pert_iname, gs));
        % multi-pool signatures are not supported
        assert(isequal(length(upool_id), 1), 'multipool signatures are not supported')
        if isequal(upool_id{1}, 'epsilon')
            target_is_lm = epsilon_dict.isKey(cgs_pert_iname);
        else
            target_is_lm = deltap_dict.isKey(cgs_pert_iname);
        end
        target_is_bing = 0;
        if ~isempty(ridx)
            rnk = rankorder(czs, 'fixties', false, 'direc', 'descend');
            rnk_bing = ones(size(rnk))*-666;
            rnk_bing(bing_idx) = rankorder(czs(bing_idx),'fixties', false, 'direc', 'descend');
            
            if target_is_lm
                if isequal(upool_id{1}, 'epsilon')
                    target_ridx = epsilon_dict(cgs_pert_iname);
                else
                    target_ridx = deltap_dict(cgs_pert_iname);
                end
                target_zs = czs(target_ridx);
                target_rank_full = rnk(target_ridx);
                target_rank_bing = rnk_bing(target_ridx);
                target_is_bing = rnk_bing(target_ridx)>0;
            else
                [target_zs, min_zs_idx] = min(czs(ridx));
                target_ridx = ridx(min_zs_idx);
                target_rank_full = rnk(target_ridx);
                target_rank_bing = rnk_bing(target_ridx);
                target_is_bing = rnk_bing(target_ridx)>0;
            end
        else
            target_zs = -666;
            target_rank_full = -666;
            target_rank_bing = -666;
        end
        
        cgs_annot(ii).distil_ss = ss;
        cgs_annot(ii).distil_cc_q75 = ifelse(isnan(cc_q75),-666,cc_q75);
        cgs_annot(ii).distil_id = print_dlm_line({annot(cidx).sig_id}, 'dlm', ',');
        if isequal(num_sister, 1)
            cgs_annot(ii).distil_nsample = num_sig;
        else            
            cgs_annot(ii).distil_nsample = num_sister;
        end
        
        cgs_annot(ii).pert_id = cgs_id{ii};
        cgs_annot(ii).pert_iname = cgs_pert_iname;
        cgs_annot(ii).cell_id = cgs_cell_id;
        cgs_annot(ii).pert_itime = cgs_pert_itime;
        cgs_annot(ii).pert_idose = cgs_pert_idose;
        cgs_annot(ii).pert_type = cgs_pert_type;
        
        cgs_annot(ii).distil_nrep = num_sig;
        cgs_annot(ii).distil_wt = print_dlm_line(norm_wt, 'dlm', ',', 'precision', 2);
        cgs_annot(ii).distil_cc_pw = print_dlm_line(tri2vec(cc, 1, false), 'dlm', ',', 'precision', 2);
        cgs_annot(ii).cgs_vs_sister_cc = print_dlm_line(cgs_vs_sister_cc, ...
            'dlm', ',', ...
            'precision', 2);
        cgs_annot(ii).distil_pert_id = print_dlm_line(upid, 'dlm', ',');
        
        cgs_annot(ii).pool_id = print_dlm_line(upool_id, 'dlm', ',');
        cgs_annot(ii).brew_prefix = print_dlm_line(ubrew_id, 'dlm', ',');
        cgs_annot(ii).num_brew = length(ubrew_id);
        %         cgs_annot(ii).cgs_num_pool = length(upool_id);
        %
        cgs_annot(ii).target_is_lm = target_is_lm;
        cgs_annot(ii).target_is_bing = target_is_bing;
        cgs_annot(ii).target_zs = target_zs;
        cgs_annot(ii).target_rank_full = target_rank_full;
        cgs_annot(ii).target_rank_bing = target_rank_bing;
    end
end

t = toc(t0);
disp(t);

keep=find(gpsz>1);
cgs = mkgctstruct(cgs_mat(:, keep), 'cid', cgs_id(keep), 'rid', score.rid);
cgs_annot = cgs_annot(keep);

end