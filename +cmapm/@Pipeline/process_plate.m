function [gex_ds, qnorm_ds, inf_ds, zs_ds_qnorm, zs_ds_inf] = process_plate(varargin)
% PROCESS_PLATE - Run the L1000 data processing pipeline
% for a plate of data.
% This script provides a wrapper around the scripts:
% - level1_to_level2
% - level2_to_level3
% - level3_to_level4
%
% Script outputs are saved under plate_path and
% level 2, 3, and 4 matrices are returned to the workspace.
% 
% Outputs:
%	
%	gex_ds			raw gene expression data (level 2)
% 	qnorm_ds		L1000 invariant set scaled and quantile normalized gene expression profiles in landmark space (level 3)
%	inf_ds			same as qnorm_ds but in full gene space
%	zs_ds_qnorm		population-based differential expression values in landmark space (level 4)
%	zs_ds_inf		same as zs_ds_qnorm but in full gene space
%
% Arguments:
% 
%	Parameter	Value
%	plate 		the name of the directory of LXB files
%	plate_path	the path to save output
% 	raw_path	the path to the directory containing plate
% 	map_path 	the path to the directory containing the a file with sample annotations
% 
% Example:
%  [gex_ds, qnorm_ds, inf_ds, zs_ds_qnorm, zs_ds_inf] = process_plate('plate', 'LJP009_A375_24H_X1_B20', ...
% 'raw_path', fullfile(cmapmpath, '../data/lxb'), 'map_path', fullfile(cmapmpath, '../data/maps'));

toolname = mfilename;
fprintf('-[ %s ]- Start\n', upper(toolname));
% startup_defaults;
pnames = {'plate', 'overwrite', 'precision', ...
    'flipcorrect', 'parallel', 'randomize',...
    'use_smdesc', 'lxbhist_analyte', 'lxbhist_well',...
    'detect_param', 'setrnd', 'rndseed', ...
    'incomplete_map', 'plate_path'};
dflts = { '', false, 1, ...
    true, true, false, ...
    false, '25,182,286,373,463', 'A05,N13,G17',...
    fullfile(cmapmpath,'resources', 'detect_params.txt'), true, '', ...
    false, '.'};
args = parse_args(pnames, dflts, varargin{:});

% Run peak deconvolution
dpeak_pipe(varargin{:});

% Apply flip adjustment heuristics
gex_ds = flipadjust_pipe(varargin{:});

% Normalize the dataset using LISS
norm_ds = liss_pipe(varargin{:});

% Apply quantile normalization
qnorm_ds = qnorm_pipe(norm_ds, fullfile(args.plate_path, args.plate), 'plate', args.plate);

% Run inference model
inf_ds = infer_pipe(qnorm_ds, fullfile(args.plate_path, args.plate), varargin{:});

% Compute population-based, robust z-scores for landmark genes
zs_ds_qnorm = qnorm_ds;
zs_ds_qnorm.mat = robust_zscore(zs_ds_qnorm.mat, 2, varargin{:});

% save the dataset
mkgct(fullfile(args.plate_path, args.plate, sprintf('%s_ZSPCQNORM', args.plate)), zs_ds_qnorm);

% Compute population-based robust z-scores for all genes
zs_ds_inf = inf_ds;
zs_ds_inf.mat = robust_zscore(zs_ds_inf.mat, 2, varargin{:});

% save the dataset
mkgct(fullfile(args.plate_path, args.plate, sprintf('%s_ZSPCINF', args.plate)), zs_ds_inf);

fprintf('-[ %s ]- Done\n', upper(toolname));

end