function [ncs, rpt, pos_mean, neg_mean] = normalizeQuery(cs, tsid, varargin)
% NORMALIZEQUERY Compute normalized connectivity scores. 
% NCS = NORMALIZEQUERY(CS, TSID) The connectivity scores CS are scaled by the
% signed mean derived from the distribution of scores stratified by cell
% line and perturbagen type. In other words every element in CS is scaled
% by the 

% 
%   NCS(i,c,t) = 0, if CS(i,c,t) == 0 
%   NCS[i,c,t] = CS(i,c,t) / PosMean(c,t), if CS(i,c,t)>0 
%   NCS(i,c,t) = - CS(i,c,t) / NegMean(c,t), if CS(i,c,t)<0
%
% where 
%   PosMean_cx_ty = mean(CS_cx_ty[ipos, j]); ipos = CS_cx_ty[:, j]>0
%   NegMean_cx_ty = mean(CS_cx_ty[ineg, j]); ineg = CS_cx_ty[:, j]<0

% Grouping variables
cs_type = ds_get_meta(cs, 'row', 'pert_type');
% assume trt_poscon is trt_cp
cs_type = strrep(cs_type, 'trt_poscon', 'trt_cp');
cs_cell = ds_get_meta(cs, 'row', 'cell_id');
csgp = strcat(cs_type,':',cs_cell);

% intersect ids with TS
[ts_rid, ridx_ts, ridx_cs] = intersect(tsid, cs.rid, 'stable');
assert(isequal(numel(ts_rid), numel(tsid)),...
        'Some touchstone signatures missing from query dataset')

% touchstone groups
ts_type = cs_type(ridx_cs);
ts_cell = cs_cell(ridx_cs);
tsgpvar = csgp(ridx_cs);
[tsgpn, tsgpidx] = getcls(tsgpvar);
% Normalized scores
ncs = cs;

% mean rpt
[ucsgp, uidx] = unique(csgp);
ucsgp_lut = mortar.containers.Dict(ucsgp);
ucs_type = cs_type(uidx);
ucs_cell = cs_cell(uidx);

rpt = struct('group', ucsgp,...
             'pert_type', ucs_type,...
             'cell_id', ucs_cell,...
             'mean_group', '-666',...
             'pos_mean', nan,...
             'neg_mean', nan);

nucsgp = length(ucsgp);         
mu_pos = nan(nucsgp, size(cs.mat, 2));
mu_neg = nan(nucsgp, size(cs.mat, 2));
processed = false(nucsgp, 1);
% tsgpidx = ts.mat(:, ii);
% tsgpvar = ds_get_meta(ts, 'row', ts.cid(ii));
% useme = find(~isnan(tsgpidx));
% [~, uidx] = unique(tsgpidx(useme));
% tsgpn = tsgpvar(useme(uidx));
ntsgp = length(tsgpn);

for jj=1:ntsgp
    this_csgp = strcmp(csgp, tsgpn{jj});
    if any(this_csgp)
        this_tsgp = abs(tsgpidx - jj) < eps;
        rpt_idx = ucsgp_lut(tsgpn{jj});
        
        % TS scores for this group
        x = cs.mat(ridx_cs(this_tsgp), :);
        % All scores for this group
        y = cs.mat(this_csgp, :);
        
        pos_x = x>0;
        neg_x = x<0;
        
        pos_y = y>0;
        neg_y = y<0;
        
        if any(pos_x(:))
            % Positive mean
            tmp = x;
            % mask non-positive values
            tmp(~pos_x) = nan;
            pos_mu = clip(nanmean(tmp, 1), 0.01, inf);
            
            % normalize all members of this group
            tmp_y = y;
            tmp_y = tmp_y ./repmat(pos_mu, size(tmp_y, 1), 1);
            y(pos_y) = tmp_y(pos_y);
            
            % stats
            mu_pos(rpt_idx,:) = pos_mu;
            rpt(rpt_idx).pos_mean = mean(pos_mu);
            rpt(rpt_idx).mean_group = tsgpn{jj};
            processed(rpt_idx) = true;
        end
        
        if any(neg_x(:))
            % Negative mean
            % mask non-negative values
            tmp = x;
            tmp(~neg_x) = nan;
            neg_mu = clip(-nanmean(tmp, 1), 0.01, inf);
            
            % normalize all members in this gp
            tmp_y = y;
            tmp_y = tmp_y./repmat(neg_mu, size(tmp_y, 1), 1);
            y(neg_y) = tmp_y(neg_y);
            
            % stats
            mu_neg(rpt_idx,:) = neg_mu;
            rpt(rpt_idx).neg_mean = mean(neg_mu);
            rpt(rpt_idx).mean_group = tsgpn{jj};
            processed(rpt_idx) = true;
        end
        ncs.mat(this_csgp, :) = y;
    end
end

nproc = nnz(processed);
dbg(1, '%d / %d groups processed using pert_type:cell_id', nproc, nucsgp);


% First handle unprocessed groups using cell_id
if any(~processed)
    nproc0 = nnz(processed);
    [ncs, mu_pos, mu_neg, rpt, processed] = normalizeUnprocessed(...
                                            ncs, mu_pos, mu_neg,...
                                            rpt, processed, ucsgp_lut,...
                                            ucs_cell, csgp);
    nproc = nnz(processed);
    dbg(1, '%d / %d rows normalized using cell_id', nproc-nproc0, nucsgp);
end

% then try pert_type
if any(~processed)
    nproc0 = nnz(processed);
    [ncs, mu_pos, mu_neg, rpt, processed] = normalizeUnprocessed(...
                                                ncs, mu_pos, mu_neg,...
                                                rpt, processed, ucsgp_lut,...
                                                ucs_type, csgp);
    nproc = nnz(processed);
    dbg(1, '%d / %d groups normalized using pert_type', nproc-nproc0, nucsgp);
end

% finally try random sampling
if any(~processed)
    nproc0 = nnz(processed);
    [ncs, mu_pos, mu_neg, rpt, processed] = normalizeUnprocessed(...
                                                ncs, mu_pos, mu_neg,...
                                                rpt, processed, ucsgp_lut,...
                                                'random', csgp);
    nproc = nnz(processed);
    dbg(1, '%d / %d rows normalized using random sampling', nproc-nproc0, nucsgp);                                            
end

pos_mean = mkgctstruct(mu_pos, 'rid', ucsgp, 'cid', ncs.cid);
neg_mean = mkgctstruct(mu_neg, 'rid', ucsgp, 'cid', ncs.cid);

end

function [ncs, mu_pos, mu_neg, rpt, processed] = normalizeUnprocessed(...
                    ncs, mu_pos, mu_neg, rpt,...
                    processed, ucsgp_lut, ucs_gpvar,...
                    cs_gpvar)

unproc = ~processed;
ucsgp = ucsgp_lut.sortKeysOnValue;
unproc_gp = ucsgp(unproc);
if strcmp('random', ucs_gpvar)
    ngp = length(rpt);
    ucs_gpvar = cell(ngp, 1);    
    idx = union(randsample(find(processed), min(10, ngp)), find(unproc));
    ucs_gpvar(idx) = {'random'};
end

[gp_name, gp_idx] = getcls(ucs_gpvar(unproc));
nucst = length(gp_name);

for ii=1:nucst
    this_gp_idx = gp_idx == ii;
    useme = strcmp(ucs_gpvar, gp_name{ii}) & processed;
    if any(useme)
        this_ucsgp = unproc_gp(this_gp_idx);
        this_cs = ismember(cs_gpvar, this_ucsgp);
        y = ncs.mat(this_cs, :);
        rpt_idx = ucsgp_lut(this_ucsgp);
        pos_y = y>0;
        neg_y = y<0;
        if any(pos_y(:))
            pos_mu = nanmedian(mu_pos(useme, :));
            tmp_y = y;
            tmp_y = tmp_y ./repmat(pos_mu, size(tmp_y, 1), 1);
            y(pos_y) = tmp_y(pos_y);
            mu_pos(rpt_idx, :) = repmat(pos_mu, size(rpt_idx, 1), 1);
            processed(rpt_idx) = true;
            [rpt(rpt_idx).pos_mean] = deal(mean(pos_mu));            
            [rpt(rpt_idx).mean_group] = deal(gp_name{ii});
        end
        if any(neg_y(:))
            neg_mu = nanmedian(mu_neg(useme, :));
            tmp_y = y;
            tmp_y = tmp_y./repmat(neg_mu, size(tmp_y, 1), 1);
            y(neg_y) = tmp_y(neg_y);
            
            mu_neg(rpt_idx, :) = repmat(neg_mu, size(rpt_idx, 1), 1);
            processed(rpt_idx) = true;
            [rpt(rpt_idx).neg_mean] = deal(mean(neg_mu));
            [rpt(rpt_idx).mean_group] = deal(gp_name{ii});

        end
        ncs.mat(this_cs, :) = y;
    end
end

end
