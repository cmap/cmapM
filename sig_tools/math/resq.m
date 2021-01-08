function res = resq(ds_score, query_gmt, ds_sim, feature_info, feature_field)
% Compute Relative Effect Size of Query (RESQ) metric
% RESQ_DS = RESQ(DS_SCORE, QUERY_GMT, DS_SIM)
% SES: Signature effect size across all features
%   SES = MAXQ(X, 25, 75)
% SES: Query Effect size for QIDX features
%   QES = MAXQ(X(QIDX), 25, 75)
% RESQ_FC: Fold Change Query [0, Inf]
%   RESQ_FC = QES / SES
% RESQ_AMP: Relative Effect Size of the Query [-2, 2]
%   RESQ = 2*(RESQ_FC - 1) / (RESQ_FC + 1)
% Bounds
%   RESQ = -2, when FCQ = 0
%   RESQ = -0.67 when FCQ = 0.5
%   RESQ = 0, then FCQ = 1 
%   RESQ = +0.67 when FCQ = 2

% dataset of scores [F features x N samples]
ds_score = parse_gctx(ds_score);
[num_feature, num_sample] = size(ds_score.mat);
ds_score = annotate_ds(ds_score, feature_info, 'dim', 'row');

% queries (Q)
query_gmt = parse_geneset(query_gmt);
num_query = length(query_gmt);

% Dataset of similarity scores corresponsing to 
% queries and score dataset [N samples x Q queries]
ds_sim = parse_gctx(ds_sim, 'rid', ds_score.cid);

% sanity checks
assert(isequal(ds_sim.rid, ds_score.cid), 'Column mismatch');
assert(isequal(length(ds_sim.cid), num_query), 'Query mismatch');

features = ds_get_meta(ds_score, 'row', feature_field);
feature_lut = mortar.containers.Dict(features);

%q = [25, 75];
q = [50, 50];

% signature effect size
ses = prctile(ds_score.mat, q, 1);

% Query effect size: maxq of query features based on sign of similarity
qes = zeros(num_sample, num_query);

% RESQ_FC: Relative effect size of query features
% Fold change of query to signature effect size
resq_fc = zeros(num_sample, num_query);

% RESQ_AMP: Amplitude transform on RESQ_FC
resq_amp = zeros(num_sample, num_query);

% NRESQ_FC: RESQ_FC normalized for set size
nresq_fc = zeros(num_sample, num_query);

set_size = [query_gmt.len]';

for ii=1:num_query
    this_set = query_gmt(ii).entry;
    this_ridx = feature_lut(this_set);
    p = prctile(ds_score.mat(this_ridx, :), q, 1);
    sgn = sign(ds_sim.mat(:, ii)');
    pick = sub2ind(size(p), (sgn>=0)+1, 1:num_sample);
    qes(:, ii) = p(pick);
    fc = p(pick)./ses(pick);
    nfc = fc ./ clip(mean(fc), 0.1, inf);
    resq_fc(:, ii) = fc;
    nresq_fc(:, ii) = nfc;
    resq_amp(:, ii) = 2*(fc - 1)./(fc + 1);
end

ds_ses = mkgctstruct(ses, 'rid', gen_labels(q, 'prefix', 'q'), 'cid', ds_score.cid);

ds_qes = ds_sim;
ds_qes.mat = qes;

ds_resq_amp = ds_sim;
ds_resq_amp.mat = resq_amp;

ds_resq_fc = ds_sim;
ds_resq_fc.mat = resq_fc;

ds_nresq_fc = ds_sim;
ds_nresq_fc.mat = nresq_fc;

res = struct('resq_amp', ds_resq_amp,...
       'resq_fc', ds_resq_fc,...
       'nresq_fc', ds_nresq_fc,...
       'qes', ds_qes,...       
       'ses', ds_ses);
   
end
