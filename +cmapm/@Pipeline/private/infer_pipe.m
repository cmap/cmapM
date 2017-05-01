function infds = l1kt_infer(ds, out, varargin)
% L1KT_INFER Infer expression levels of dependent genes based on expressions
% of landmarks
%   INFDS = L1KT_INFER(DS,OUT) takes as input a .gct structure or the path
%   to a .gct file with normalized landmark gene expression values. It
%   returns the inferred data set to the MATLAB workspace, and saves the
%   data set in the directory specified by OUT.
%
%   INFDS = L1KT_INFER(DS,OUT,'PARAM1',VAL1,'PARAM2',VAL2,...) specifies
%   additional parameters and their values. The parameters are the
%   following:
%       Parameter   Value
%        'model'       File path to the .mat file containing model weights.
%                    Default is '../data/mlr12k_epsilon5253_978.mat'
%        'chip'      The .chip file to use; should not need to change this
%        'annpath'  The path to the .chip annotation file; default is in
%                     ../data

% Get optional arguments
pnames = {'model', 'chip', 'annpath', 'plate'};
dflts = {...
	fullfile(cmapmpath, 'resources', 'mlr12k_epsilon5253_978.mat'),...
	 'HG_U133A',...
	 fullfile(cmapmpath, 'resources'), ''};
args = parse_args(pnames,dflts,varargin{:});
print_args('l1kt_infer', 1, args)

% perform inference
infds = infer_tool('res', ds, 'model', args.model, varargin{:});
infds = sort_features(infds);
% save dataset
mkgct(fullfile(out, sprintf('%s_INF', args.plate)), infds);