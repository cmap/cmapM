function [ncs, rpt, pos_mean, neg_mean] = normalizeQueryRefV2(cs, rid_ref, gp_field)
% normalizeQueryRefV2 Compute normalized connectivity scores (new version for sig_queryl1k). 
% NCS = normalizeQueryRefV2(CS, RID, GP) The connectivity scores are scaled by the
% signed mean of the connectivity scores corresponding to row ids RID.

[cmn_rid, ~, ridx_cs] = intersect(rid_ref, cs.rid, 'stable');
assert(isequal(numel(cmn_rid), numel(rid_ref)),...
        'Some reference signatures missing from query dataset')
is_rid_ref = false(length(cs.rid), 1);
is_rid_ref(ridx_cs) = true;
ncs = cs;

% mean rpt
% grouping variable
[csgp, gpidx, gpn] = get_groupvar(cs.rdesc, cs.rhd, gp_field);
%[gpn, gpidx] = getcls(csgp);
[~, uidx] = unique(gpidx, 'stable');
gp_lut = mortar.containers.Dict(gpn);

rpt = struct('group', gpn,...
    'mean_group', '-666',...
    'pos_mean', nan,...
    'neg_mean', nan);

ngp = length(gpn);
mu_pos = nan(ngp, size(cs.mat, 2));
mu_neg = nan(ngp, size(cs.mat, 2));
processed = false(ngp, 1);

for jj=1:ngp
    % all members of this group
    this_gp = gpidx==jj;
    % all ref members of this group
    this_ref = this_gp & is_rid_ref;
    if any(this_ref)
        rpt_idx = gp_lut(gpn{jj});
        
        % scores for Ref in this group
        x = cs.mat(this_ref, :);
        % score for all members of this group
        y = cs.mat(this_gp, :);
        
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
            rpt(rpt_idx).pos_mean = nanmean(pos_mu);
            rpt(rpt_idx).mean_group = gpn{jj};
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
            rpt(rpt_idx).neg_mean = nanmean(neg_mu);
            rpt(rpt_idx).mean_group = gpn{jj};
            processed(rpt_idx) = true;
        end
        ncs.mat(this_gp, :) = y;
    end
end


% normalize unprocessed groups by random sampling across groups
if any(~processed)
    dbg(1, 'Some groups were not normalized, using random sampling');
    [ncs, mu_pos, mu_neg, rpt, processed] = normalizeUnprocessed(...
                                                ncs, mu_pos, mu_neg,...
                                                rpt, processed, gp_lut,...
                                                'random', csgp);
end

pos_mean = mkgctstruct(mu_pos, 'rid', gpn, 'cid', ncs.cid);
neg_mean = mkgctstruct(mu_neg, 'rid', gpn, 'cid', ncs.cid);

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
            pos_mu = nanmedian(mu_pos(useme, :), 1);
            tmp_y = y;
            tmp_y = tmp_y ./repmat(pos_mu, size(tmp_y, 1), 1);
            y(pos_y) = tmp_y(pos_y);
            mu_pos(rpt_idx, :) = repmat(pos_mu, size(rpt_idx, 1), 1);
            processed(rpt_idx) = true;
            [rpt(rpt_idx).pos_mean] = deal(mean(pos_mu));            
            [rpt(rpt_idx).mean_group] = deal(gp_name{ii});
        end
        if any(neg_y(:))
            neg_mu = nanmedian(mu_neg(useme, :), 1);
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
