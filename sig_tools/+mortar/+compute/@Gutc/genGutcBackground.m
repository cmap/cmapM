function genGutcBackground(build_path, introspect_path, out_path, varargin)
% genGutcBackground Compute background distributions and PS lookup for GUTC
%   genGutcBackground(BUILD_PATH, INTROSPECT_PATH, OUT_PATH) BUILD_PATH is
%   the path to an L-build output by sig_build_tool. INTROSPECT_PATH is the
%   corresponding output of sig_introspect_tool for the L-build. OUT_PATH
%   is the location where outfiles will be saved.
%

import mortar.util.Message

ncs_pat = fullfile(introspect_path, 'ncs_n*.gctx');
siginfo_pat = fullfile(build_path, 'siginfo.txt');
[~, ncs_file] = find_file(ncs_pat);
if length(ncs_file)==1
    ncs_file = ncs_file{1};
else
    if length(ncs_file)>1
        error('Multiple NCS introspect files at: %s', ncs_pat);
    else
        error('NCS introspect file not found at: %s', ncs_pat);
    end
end

[~, siginfo_file] = find_file(siginfo_pat);
if length(siginfo_file)==1
    siginfo_file = siginfo_file{1};
else
    if length(siginfo_file)>1
        error('Multiple siginfo files found in build at: %s', siginfo_pat);
    else
        error('siginfo file not found in build at: %s', siginfo_pat);
    end
end

%%
% mortar.compute.Gutc.getBackgroundFiles
% ts_rpt = struct('annot_sig', 'annot/siginfo_n*.txt',...
%                 'annot_pert_cell', 'annot/pert_cell_n*.txt',...
%                 'annot_pert_summary', 'annot/pert_summary_n*.txt',...
%                 'pcl_set', 'annot/pcl_n*.gmt',...
%                 'ns2ps_sig', 'sig/ns2ps.gctx',...
%                 'ns2ps_pert_cell', 'pert_cell/ns2ps.gctx',...
%                 'ns2ps_pert_summary', 'pert_summary/ns2ps.gctx',...
%                 'ns2ps_pcl_cell', 'pcl_cell/ns2ps.gctx',...
%                 'ns2ps_pcl_summary', 'pcl_summary/ns2ps.gctx');
% Minimally for enabling signature level results the following are needed:
%   'annot_sig', 'annot/siginfo_n*.txt'
%   'ns2ps_sig', 'sig/ns2ps*.gctx'

mkdirnotexist(out_path);
ncs = parse_gctx(ncs_file);
ncs = annotate_ds(ncs, siginfo_file);
siginfo = gctmeta(ncs);
siginfo = mvfield(siginfo, 'cid', 'sig_id');
nsig = length(siginfo);

%% signature-level distributions
Message.debug(1, '# Saving annotations for %d signatures', nsig);
% annotations
annot_path = mkdirnotexist(fullfile(out_path, 'annot'));
annot_sig_file = fullfile(annot_path, 'siginfo.txt');
jmktbl(annot_sig_file, siginfo);

%% NS2PS transform
% NOTE: For large datasets this might exceed memory, in which case need to
% read the introspect dataset in chunks

% compute bkg using signatures from the same cell line
[cell_id_gp, cell_id_num] = getcls({siginfo.cell_id}');
ncell_gp = length(cell_id_gp);
is_not_same_cell = bsxfun(@ne, cell_id_num, cell_id_num');
ncs.mat(is_not_same_cell) = nan;

Message.debug(1, '# Computing background using signatures from the same cell line for %d lines', ncell_gp);
% Compute percentiles and assess stats
[ns2ps_sig, stats_sig] = mortar.compute.Gutc.scoreToPercentileTransform(...
    ncs, 2, -4, 4, 10001, 'method', 'symmetric');
%%
sig_bkg_path = mkdirnotexist(fullfile(out_path, 'sig'));
mkgctx(fullfile(sig_bkg_path, 'ns2ps.gctx'), ns2ps_sig, 'appenddim', false);
mkgctx(fullfile(sig_bkg_path, 'stats.gctx'), stats_sig, 'appenddim', false);
end