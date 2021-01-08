function [ncs, rpt, pos_mean, neg_mean] = normalizeQueryOOB(cs, ts, varargin)
% NORMALIZEQUERY Compute normalized connectivity scores. 
% NCS = NORMALIZEQUERY(CS, TS) The connectivity scores are scaled by the
% signed mean of the provided scores.

% group_var = {'cell_id', 'pert_type'};
% dbg(1, 'Split query by %s...', print_dlm_line(group_var, 'dlm', ','));

% assignment grouping variable
% agp = ds_get_meta(ts, 'row', 'assign');
cs_type = cs.rdesc(:, cs.rdict('pert_type'));
% assume trt_poscon is trt_cp
cs_type = strrep(cs_type, 'trt_poscon', 'trt_cp');

cs_cell = cs.rdesc(:, cs.rdict('cell_id'));
csgp = strcat(cs_type,':',cs_cell);


% % restrict rows to just touchstone signatures
% cs = ds_slice(cs, 'rid', ts.rid);

[ts_rid, ridx_ts, ridx_cs] = intersect(ts.rid, cs.rid, 'stable');
assert(isequal(numel(ts_rid), numel(ts.rid)),...
        'Some touchstone signatures missing from query dataset')
ncs = cs;

[~, nc_ts] = size(ts.mat);

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

for ii=1:nc_ts
    % 
    tsgpidx = ts.mat(:, ii);    
    tsgpvar = ds_get_meta(ts, 'row', ts.cid(ii));
    useme = find(~isnan(tsgpidx));
    [~, uidx] = unique(tsgpidx(useme));
    tsgpn = tsgpvar(useme(uidx));
    ntsgp = length(tsgpn);
    
    for jj=1:ntsgp        
        this_csgp = strcmp(csgp, tsgpn{jj});
        if any(this_csgp)
            this_tsgp = abs(tsgpidx - jj) < eps;
            rpt_idx = ucsgp_lut(tsgpn{jj});
            
            % scores for this group
            x = cs.mat(ridx_cs(this_tsgp), :);
            y = cs.mat(this_csgp, :);
            
            pos_x = x>0;
            neg_x = x<0;
            
            pos_y = y>0;
            neg_y = y<0;
            
            if any(pos_x(:))
                tmp = x;
                % mask non-positive values
                tmp(~pos_x) = nan;
                pos_mu = clip(nanmean(tmp, 1), 0.01, inf);
                
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
                % mask non-negative values
                tmp = x;
                tmp(~neg_x) = nan;
                neg_mu = clip(-nanmean(tmp, 1), 0.01, inf);
                
                % assign to all members in this gp
                tmp_y = y;
                tmp_y = tmp_y./repmat(neg_mu, size(tmp_y, 1), 1);
                y(neg_y) = tmp_y(neg_y);
                
                mu_neg(rpt_idx,:) = neg_mu;
                rpt(rpt_idx).neg_mean = mean(neg_mu);
                rpt(rpt_idx).mean_group = tsgpn{jj};
                processed(rpt_idx) = true;
            end            
            ncs.mat(this_csgp, :) = y;
        end
    end
end

% first handle unprocessed groups based on pert_type
if any(~processed)
    [ncs, mu_pos, mu_neg, rpt, processed] = normalizeUnprocessed(...
                                                ncs, mu_pos, mu_neg,...
                                                rpt, processed, ucsgp_lut,...
                                                ucs_type, csgp);
end

% then try cell_id
if any(~processed)
    [ncs, mu_pos, mu_neg, rpt, processed] = normalizeUnprocessed(...
                                            ncs, mu_pos, mu_neg,...
                                            rpt, processed, ucsgp_lut,...
                                            ucs_cell, csgp);
end

% finally try random sampling
if any(~processed)
    [ncs, mu_pos, mu_neg, rpt, processed] = normalizeUnprocessed(...
                                                ncs, mu_pos, mu_neg,...
                                                rpt, processed, ucsgp_lut,...
                                                'random', csgp);
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
