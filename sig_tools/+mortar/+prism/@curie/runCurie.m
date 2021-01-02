function qres = runCurie(varargin)

[args, help_flag] = getArgs(varargin{:});

if ~help_flag
    % load and validate inputs
    dbg(1, '## Loading data');
    qo = loadData(args);
    
    % run the query    
    dbg(1, '## Running queries');
    qres = mortar.compute.Connectivity.runCmapQuery('up', qo.up,...
        'dn', qo.down, 'rank', qo.rank,...
        'metric', args.metric, 'es_tail', args.es_tail,...
        'score', qo.score,...
        'sig_meta', args.sig_meta,...
        'query_meta', args.query_meta);
    qres.unmapped_up = qo.unmapped_up;
    qres.unmapped_down = qo.unmapped_down;
    
    % normalize the scores
    req_fn = {'pert_id', 'cell_id', 'pert_type'};
    missing_fn = find(~ismember(req_fn, qres.cs.rhd));
    for ii=1:length(missing_fn)
        dbg(1, 'Inserting placeholder for missing metadata field:%s', req_fn{missing_fn(ii)});
        qres.cs = ds_add_meta(qres.cs, 'row', req_fn{missing_fn(ii)}, '-666');
    end
    dbg(1, '## Normalizing scores');
    qres.ncs = mortar.compute.Gutc.normalizeQueryRef(qres.cs, qres.cs.rid);
    
    % Compute percentile ranks
    dbg(1, '## Ranking scores');
    qres.pctrank_col = mortar.prism.curie.rankCurieScore(qres.ncs, 'column');
    qres.pctrank_row = mortar.prism.curie.rankCurieScore(qres.ncs, 'row');
else
    dbg(1, '## Help requested, exiting');
end

end

function qo = loadData(args)
qo = struct('score', [],...
            'rank', [],...
            'up', [],...
            'down', [],...
            'unmapped_up', [],...
            'unmapped_down', [],...
            'chip', []);
qo.score = parse_gctx(args.score);
qo.rank = parse_gctx(args.rank);
switch args.metric
    case {'wtcs', 'cs'}
        [qo.up, qo.down] = readGenesets(args.es_tail, args.up, args.down);
    otherwise
        error('%s metric unsupported', args.metric);
end
qo.chip = mortar.common.Chip.get_chip(args.platform, 'all');
assert(isfield(qo.chip, args.feature_space),...
    'Feature id %s not found for platform %s', args.feature_space, args.platform);
nup = length(qo.up);
ndown = length(qo.down);
dbg(1, '## Cell sets read %d UP sets %d DOWN sets', nup, ndown);

if ~isequal(args.feature_space, 'feature_id')
    dbg(1, '## Mapping features to feature_id');        
    [qo.up, qo.unmapped_up] = mortar.compute.MapFeatures.mapGeneWithChip(...
                            args.platform, 'all', qo.up,...
                            args.feature_space, 'feature_id');
    [qo.down, qo.unmapped_down] = mortar.compute.MapFeatures.mapGeneWithChip(...
                            args.platform, 'all', qo.down,...
                            args.feature_space, 'feature_id');                        
end
% TOADD checkGenesets()
% exclude sets with very few members members
dbg(1, '## Excluding sets with size < %d', args.min_set_size);
feature_space = qo.score.rid;
[qo.up, excluded_up] = setfilter(qo.up, feature_space, args.min_set_size, inf);
[qo.down, excluded_down] = setfilter(qo.down, feature_space, args.min_set_size, inf);

qo.unmapped_up = merge_geneset({qo.unmapped_up, excluded_up});
qo.unmapped_down = merge_geneset({qo.unmapped_down, excluded_down});

nup_include = length(qo.up);
ndown_include = length(qo.down);
dbg(1, '## %d/%d UP sets were retained', nup_include , nup);
dbg(1, '## %d/%d DOWN sets were retained', ndown_include , ndown);

end

function [up, down] = readGenesets(es_tail, up, down)
switch(lower(es_tail))
    case 'both'
        up = parse_geneset(up);
        down = parse_geneset(down);
    case 'up'
        up = parse_geneset(up);
        down = mkgmtstruct({},{},{});
    case 'down'
        up = mkgmtstruct({},{},{});
        down = parse_geneset(down);
    otherwise
        error('Invalid es_tail, expected {both, up, down}, got %s', es_tail);
end

end

function [args, help_flag]  = getArgs(varargin)

className = mfilename('class');
configFile = mortar.util.File.getArgPath(mfilename, className);
options = struct('prog', mfilename);
[args, help_flag]  = mortar.common.ArgParse.getArgs(configFile,...
    options, varargin{:});

end