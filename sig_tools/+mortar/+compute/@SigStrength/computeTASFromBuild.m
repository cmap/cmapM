function rpt = computeTASFromBuild(sig_info_file, modz_file)
% Compute TAS for signatures in a build
% rpt = computeTASFromBuild(sig_info_file, modz_file)
sig_info = parse_record(sig_info_file);
req_fn = {'sig_id', 'distil_cc_q75', 'distil_nsample'};
if ~(all(isfield(sig_info, req_fn)))
    disp(setdiff(req_fn, fieldnames(sig_info)));
    error('Required fields missing from sig info');
end
%% Read MODZ file for lm
lm_space = mortar.common.Spaces.probe('lm').asCell;
modz = parse_gctx(modz_file, 'rid', lm_space);
%% Annotate modz columns with sig info, to ensure the same ordering
modz = annotate_ds(modz, sig_info);
%% Compute Adjusted zs
nrep = ds_get_meta(modz, 'column', 'distil_nsample');
adj_zs = mortar.compute.SigStrength.adjustZscore(modz.mat, nrep);
adj_modz = modz;
adj_modz.mat = adj_zs;
%% Compute SS_ngene from adj_modz
[ss_ngene, ss_ngene_up, ss_ngene_dn] = mortar.compute.SigStrength.ssNgene(adj_modz.mat);
%% Compute TAS
cc_q75 = [sig_info.distil_cc_q75]';
% missing values
cc_q75(cc_q75<-1) = nan;
res =  mortar.compute.SigStrength.tas_ngene(ss_ngene, cc_q75, 1, true);
rpt = setarrayfield(sig_info, [], {'ss_ngene_up',...
                                   'ss_ngene_dn',...
                                   'ss_ngene',...
                                   'tas'},...              
              ss_ngene_up,...
              ss_ngene_dn,...
              ss_ngene,...
              [res.tas_gmean]');
end