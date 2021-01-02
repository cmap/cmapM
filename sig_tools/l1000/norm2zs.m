function normds = norm2zs(normds, varargin)
% NORM2ZS Compute robust z-scores from a normalized dataset

% parse args
pnames = {'min_mad'};
dflts =  {0.1};
args = parse_args(pnames, dflts, varargin{:});

if ischar(normds) && isfileexist(normds)
    normds = parse_gctx(normds);
elseif ~isstruct(normdds)
    error('Input should be a structure or a filename');
end

assert (isKey(normds.cdict, 'pert_type'), 'missing pert_type field')

% Check if compound treatment
iscp = any(strcmpi('TRT_CP', normds.cdesc(:, normds.cdict('pert_type'))));
% Compute robust Z-scores
if iscp
    % for compound plates compute zs relative to the DMSO samples
    fprintf('Detected CP plate using vehicle controls\n');
    vehidx = find(strcmpi('CTL_VEHICLE', ...
        normds.cdesc(:, normds.cdict('pert_type'))));
    normds.mat = robust_zscore(normds.mat, 2, ...
        'median_space', vehidx, ...
        'var_adjustment', 'estimate', ...
        'estimate_prct', 1, ...
        'min_mad', args.min_mad);
else
    fprintf('Detected non-CP plate using global control\n');
    normds.mat = robust_zscore(normds.mat, 2, ...
        'var_adjustment', 'estimate', ...
        'estimate_prct', 1, ...
        'min_mad', args.min_mad);
end

end