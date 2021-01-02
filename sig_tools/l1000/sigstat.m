function [ss, x] = sigstat(zs, varargin)
pnames = {'cutoff', 'ssn'};
dflts = {2, 100};
args = parse_args(pnames, dflts, varargin{:});


x = zs.mat;
% correlation stats
% keep as cell array for constructing struct
cc_max = zs.cdesc(:, zs.cdict('distil_cc_max'));
cc_median = zs.cdesc(:, zs.cdict('distil_cc_median'));
cc_q75 = zs.cdesc(:, zs.cdict('distil_cc_q75'));
nsamp = zs.cdesc(:, zs.cdict('distil_nsample'));


% number of induced features
nup = sum(x >= args.cutoff, 1)';
ndn = sum(x <= -args.cutoff, 1)';
ntot = nup + ndn;

% signal strength/TAS
strength = sig_strength(x, 'n', args.ssn);
ss_ngene = ds_get_meta(zs,'column','distil_ss_ngene');
tas = ds_get_meta(zs,'column','distil_tas');

% valid zs, set all values outside cutoff to nan
x(x < args.cutoff & x > -args.cutoff)=nan;
sig_median = nanmedian(x)';
% iqr ignores nans
sig_iqr = iqr(x, 1)';

% deal with the empty cases
sig_median(isnan(sig_median)) = 0;
% set empty to 0
sig_iqr(isnan(sig_iqr)) = 0;

tmp = struct('cc_max', cc_max,...
    'cc_median', cc_median,...
    'cc_q75', cc_q75,...
    'nsamp', nsamp,...
    'nup', num2cell(nup),...
    'ndn', num2cell(ndn),...
    'ntot', num2cell(ntot),...
    'sig_strength', num2cell(strength),...
    'sig_median', num2cell(sig_median),...
    'sig_iqr', num2cell(sig_iqr),...
    'sig_strength_ngene', num2cell(ss_ngene),...
    'tas', num2cell(tas));

meta = annot2struct(zs, 2, ...
    'keep', {'pert_id', 'pert_desc', 'cell_id', 'pert_type',...
             'pert_dose', 'pert_dose_unit', 'pert_time',...
             'pert_time_unit'});
ss = mergestruct(meta, tmp);
