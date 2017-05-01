function [qnorm_ds, inf_ds] = level2_to_level3(varargin)
% LEVEL2_TO_LEVEL3 - Given a the name of a plate and the path
% to its location, run L1000 invariant set scaling (LISS) and
% quantile normalization (QNORM). Then run inference (INF) on
% the resulting QNORM matrix. Returns the QNORM and INF 
% (level 3) matrices.
% Assumes GEX (level 2) dataset(s) exist under plate_path/plate/dpeak.
%
% Arguments:
% 
%	Parameter	Value
%	plate 		the name of the directory of LXB files
% 	plate_path	the path to the directory containing plate
%	
% 
% Example:
% [qnorm_ds, inf_ds] = level2_to_level3('plate', 'LJP009_A375_24H_X1_B20', 'plate_path', '.')

toolname = mfilename;
fprintf('-[ %s ]- Start\n', upper(toolname));
% startup_defaults;
pnames = {'plate', 'overwrite', 'plate_path', 'precision'}; 
dflts = { '', false, '.' 1}; 
arg = parse_args(pnames, dflts, varargin{:});

% run LISS
norm_ds = liss_pipe(varargin{:});

% and QNORM
qnorm_ds = qnorm_pipe(norm_ds, fullfile(arg.plate_path, arg.plate), 'plate', arg.plate);

% run inference
inf_ds = infer_pipe(qnorm_ds, fullfile(arg.plate_path, arg.plate), varargin{:});

end
