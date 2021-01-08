function res = runAnalysis(varargin)
% runAnalysis Compute t-SNE on a given matrix
% type runAnalysis('-h') for details.

[args, help_flag] = getArgs(varargin{:});

if ~help_flag
    res = main(args);
end
end

function res = main(args)
% load data
if ~isempty(args.rid)
    % custom space
    args.row_space = 'custom';
    rid =  parse_grp(args.rid);
elseif ~strcmpi(args.row_space, 'all')
    % pre-defined row_space
    is_valid_row_space = mortar.common.Spaces.probe_space.isKey(args.row_space);
    assert(is_valid_row_space, 'Invalid row space %s', args.row_space);
    rid = mortar.common.Spaces.probe(args.row_space).asCell;
else
    % default to all
    rid = '';
end

x = parse_gctx(args.ds,...
               'cid', args.cid,...
               'rid', rid);
res = struct('args', args, 'ds', '', 'cost', '');
% run tsne on the required dimension
[dim_str, dim_val] = get_dim2d(args.sample_dim);

% Apply annotations if provided
if ~isempty(args.ds_meta)
    dbg(1, 'Applying annotations from %s', args.ds_meta);
    x = annotate_ds(x, args.ds_meta, 'dim', dim_str);    
end

if isequal(dim_str, 'column')
    dbg(1, 'Using %d rows as features, transposing input matrix',...
        size(x.mat, 1))
    x = transpose_gct(x);        
else
    % feature dimension = columns
    dbg(1, 'Using %d columns as features', size(x.mat, 2))   
end

% handle missing data
switch args.missing_action
    case 'drop'
        % drop features with missing data
        x = ds_impute_missing(x, 'column', 'drop', '');
    case 'impute'
        % impute using feature means
        x = ds_impute_missing(x, 'column', 'impute', 'nanmean');  
    case 'fill'
        % fill missing values with constant
        x = ds_impute_missing(x, 'column', 'fill', args.missing_fill_value);
end

[nsample, nfeature] = size(x.mat);

% initial dims cant exceed number of samples
min_dim = min(nsample, nfeature);
args.initial_dim = min(min_dim, args.initial_dim);

% auto-select algorithm based on dataset size
if strcmp(args.algorithm, 'auto')
    if nsample>5000
        tsne_algorithm = 'barnes-hut';
    else
        tsne_algorithm = 'standard';
    end
else
    tsne_algorithm = args.algorithm;
end

if args.is_pairwise
    dbg(1, 'Assuming input values are pairwise relationships');
    [tsx, cost] = mortar.compute.TSNE.tsnePairwise(x.mat, [], args.out_dim, args.perplexity);    
else
    switch tsne_algorithm
        case 'standard'
            [tsx, cost] = ...
                mortar.compute.TSNE.simpleTsne(x.mat,...
                [],...
                args.out_dim,...
                args.initial_dim,...
                args.perplexity);
        case 'barnes-hut'
            if nsample>5000 && isequal(args.out_dim, 2)
                [tsx, lm, cost] = ...
                    mortar.compute.TSNE.fastTsne(x.mat,...
                    args.initial_dim,...
                    args.perplexity,...
                    args.theta);
            elseif nsample<=5000
                error('Barnes-Hut implementation requires >5000 samples, found %d', nsample)
            else
                error('Barnes-Hut implementation outputs only 2d dimensions, requested: %d', args.out_dim)
            end
        otherwise
            error('Unknown algorithm: %s', args.algorithm)
    end
end
% scale result to [-50, 50]
scale_factor = max(max(abs(tsx(:))), 50);
tsx = 50 * tsx / scale_factor;

res.ds = mkgctstruct(tsx, 'rid', x.rid,...
                    'rhd', x.rhd, 'rdesc', x.rdesc,...
                    'cid', gen_labels(size(tsx, 2), 'prefix', 'TS',...
                            'zeropad', false));
res.cost = cost;

end

function [args, help_flag] = getArgs(varargin)
%%% Parse arguments
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'Run a CMap query', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    %
end

end
