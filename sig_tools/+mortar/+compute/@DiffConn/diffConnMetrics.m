function rpt = diffConnMetrics(ds, pheno_field)
% diffConnMetrics Compute differential connectivity metrics
%   RPT = diffConnMetrics(DS, PHENO_FIELD)
%
% The columns of DS are partitioned into positive and negative classes
% based on the sign of the phenotype vector defined by PHENO_FIELD.
% Differential connectivity statistics are computed on each
% row of DS, resulting in RPT a structure array of length equal to the
% number of rows in DS and the following fields:
%
% pos_q : Aggregate connectivity in the positive class. If the majority of
%         scores in the positive class is positive pos_q = 25th percentile
%         of the scores else pos_q = 75th percentile of the scores. This
%         ensures that 75% of the scores in the positive class are more
%         extreme than pos_q.
% neg_q : Aggregate connectivity in the negative class. The value depends
%         on the sign of pos_q
%         if pos_q<0, then neg_q = 75th percentile of the scores
%         if pos_q>0, then neg_q = 25th percentile of the scores
% neg_q50 : Median of the negative class scores
% delta : Difference of pos_q - neg_q50
% pheno_pcc : Pearson correlation with the phenotype vector
% d_max : Delta max statistic defined as
%         d_max = (0.5 * delta) ./ max(200-abs(pos_q), 200-abs(neg_q50));
% d_min : Delta min statistic defined as
%         d_min = (0.5 * delta) ./ min(200-abs(pos_q), 200-abs(neg_q50));
% d_gain : Differential gain
%          d_gain = sign(pos_q).*sigmoid(abs(pos_q), 1, 80, 4, 1) - 
%                   sign(neg_q).*sigmoid(abs(neg_q), 1, 80, 4, 1)
% dc_score : Composite differential connectivity score
%            pos_q_scaled = scale_feature(pos_q(:), 'zero_one')
%            d_gain_scaled = scale_feature(d_gain(:), 'zero_one')
%            dc_score = sqrt(pos_q_scaled * 
% dc_score_mean : nanmean([pos_q_scaled, d_gain_scaled], 2)

pheno_vec = ds_get_meta(ds, 'column', pheno_field);

% correlation with phenotype
pheno_pcc = fastcorr(pheno_vec, ds.mat');

% connectivity of positive class
q = [25, 75];
is_pos_class = pheno_vec>0;
pos_cnx = ds.mat(:, is_pos_class);
pos_p = prctile(pos_cnx, q, 2);
% pick pos connectivity based on number of positive connections
% if majority of cnx is +ve: pos_q = q25
% if its -ve: pos_q = q75
% note zeros are ignored when counting but included when computing the stat
num_pos = nansum(pos_cnx>0, 2);
num_neg = nansum(pos_cnx<0, 2);
is_pos_majority = num_pos >= num_neg;
pos_q(is_pos_majority, 1) = pos_p(is_pos_majority, 1);
pos_q(~is_pos_majority, 1) = pos_p(~is_pos_majority, 2);

% upper and lower quantiles for negative class
neg_p = prctile(ds.mat(:, ~is_pos_class), q, 2);
% pick negative score based on the sign of positive score
% if pos_q<0, then neg_q = q75
% if pos_q>0, then neg_q = q25
pick = sub2ind(size(neg_p), (1:size(neg_p, 1))', ~is_pos_majority + 1);
neg_q = neg_p(pick);
neg_q50 = prctile(ds.mat(:, ~is_pos_class), 50, 2);

% delta metrics
delta = pos_q - neg_q50;
d_max = (0.5 * delta) ./ max(200-abs(pos_q), 200-abs(neg_q50));
d_min = (0.5 * delta) ./ min(200-abs(pos_q), 200-abs(neg_q50));
d_gain = mortar.compute.DiffConn.computeGain(pos_q, neg_q);
% composite diff conn score
% scale pos_q to [0, 1]
pos_q_scaled = scale_feature(pos_q(:), 'zero_one');
d_gain_scaled = scale_feature(d_gain(:), 'zero_one');
dc_score_mean = nanmean([pos_q_scaled, d_gain_scaled], 2);
dc_score = sqrt(clip(pos_q_scaled .* d_gain_scaled, eps, inf));

rpt = gctmeta(ds, 'row');
rpt = setarrayfield(rpt, [],...
    {'pos_q', 'neg_q', 'neg_q50',...
    'd_gain', 'dc_score', 'dc_score_mean', 'delta', 'd_max',...
    'd_min', 'pheno_pcc'},...
    pos_q, neg_q, neg_q50,...
    d_gain, dc_score, dc_score_mean, delta, d_max,...
    d_min, pheno_pcc);

end