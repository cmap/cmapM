function [ncs, rpt, pos_mean, neg_mean] = normalizeQueryRefGrouped(ncs, rid_ref, gp_field)
% normalizeQueryRefGrouped Compute normalized connectivity scores (new version for sig_queryl1k). 
% NCS = normalizeQueryRefGrouped(CS, RID, GP) The connectivity scores are
% grouped according to GP and scaled by the signed mean of the connectivity
% scores corresponding to row ids RID within the group.

[cmn_rid, ~, ridx_cs] = intersect(rid_ref, ncs.rid, 'stable');
assert(isequal(numel(cmn_rid), numel(rid_ref)),...
        'Some reference signatures missing from query dataset')
is_rid_ref = false(length(ncs.rid), 1);
is_rid_ref(ridx_cs) = true;
%ncs = ncs;

if isempty(gp_field)
    % no grouping specified, specify one global variable
    gpidx = ones(size(ncs.rid));
    gpn = {'global'};
    csgp = gpn(gpidx);
else
    % grouping variable
    [csgp, gpn, gpidx] = get_groupvar(ncs.rdesc, ncs.rhd, gp_field);
end
%[gpn, gpidx] = getcls(csgp);
[~, uidx] = unique(gpidx, 'stable');
gp_lut = mortar.containers.Dict(gpn);

% mean report
rpt = struct('group', gpn,...
    'mean_group', '-666',...
    'pos_mean', nan,...
    'neg_mean', nan);

ngp = length(gpn);
pos_means = nan(ngp, size(ncs.mat, 2));
neg_means = nan(ngp, size(ncs.mat, 2));
processed = false(ngp, 1);

for jj=1:ngp
    % all members of this group
    this_gp = gpidx==jj;
    % all ref members of this group
    this_ref = this_gp & is_rid_ref;
    if any(this_ref)
        rpt_idx = gp_lut(gpn{jj});                       
        % signed mean for Ref in this group
        [pos_mu, neg_mu] = getSignedMean(ncs.mat(this_ref, :));
        if any(~isnan(pos_mu)) || any(~isnan(neg_mu))
            ncs.mat(this_gp, :) = normalizeBySignedMean(ncs.mat(this_gp, :), pos_mu, neg_mu);            
            pos_means(rpt_idx, :) = pos_mu;
            neg_means(rpt_idx, :) = neg_mu;            
            pos_mean = nanmean(pos_mu);
            neg_mean = nanmean(neg_mu);
            rpt = setarrayfield(rpt, rpt_idx, {'pos_mean', 'neg_mean', 'mean_group'},...
                pos_mean, neg_mean, gpn{jj});
            processed(rpt_idx) = true;
        end
    end
end

% normalize unprocessed groups using the signed means of the processed groups
if any(~processed)
    dbg(1, 'Some groups were not normalized, using global distribution');
    mu_pos_grand = nanmedian(pos_means(processed, :), 1);
    mu_neg_grand = nanmedian(neg_means(processed, :), 1);
    unproc = ~processed;
    rpt_idx = find(unproc);
    unproc_ridx = ismember(gpidx, rpt_idx);
    % unprocessed rows in the connectivity matrix    
    ncs.mat(unproc_ridx, :) = normalizeBySignedMean(ncs.mat(unproc_ridx, :), mu_pos_grand, mu_neg_grand);    
    pos_means(unproc, :) = repmat(mu_pos_grand, nnz(unproc), 1);
    neg_means(unproc, :) = repmat(mu_neg_grand, nnz(unproc), 1);
    rpt = setarrayfield(rpt, rpt_idx, {'pos_mean', 'neg_mean'},...
        nanmean(mu_pos_grand), nanmean(mu_neg_grand));
    rpt = setarrayfield(rpt, rpt_idx, 'mean_group', 'global');
end

pos_mean = mkgctstruct(pos_means, 'rid', gpn, 'cid', ncs.cid);
neg_mean = mkgctstruct(neg_means, 'rid', gpn, 'cid', ncs.cid);

end

function [pos_mu, neg_mu] = getSignedMean(x)
pos_x = x>0;
neg_x = x<0;

pos_mu = nan;
neg_mu = nan;

if any(pos_x(:))
    tmp = x;
    % mask non-positive values
    tmp(~pos_x) = nan;
    pos_mu = clip(nanmean(tmp, 1), 0.01, inf);
end

if any(neg_x(:))
    % mask non-negative values
    tmp = x;
    tmp(~neg_x) = nan;
    neg_mu = clip(-nanmean(tmp, 1), 0.01, inf);
end

end

function y = normalizeBySignedMean(y, pos_mu, neg_mu)
pos_y = y>0;
neg_y = y<0;

if ~isnan(pos_mu)
    tmp_y = y;
    tmp_y = bsxfun(@rdivide, tmp_y, pos_mu);
    y(pos_y) = tmp_y(pos_y);    
end

if ~isnan(neg_mu)
    tmp_y = y;
    tmp_y = bsxfun(@rdivide, tmp_y, neg_mu);
    y(neg_y) = tmp_y(neg_y);        
end

end