function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;

% Validate datasets
if ~isempty(args.score)
    args.dataset = 'custom';
end

if ~isequal(args.dataset, 'custom')
    ds_rec = mortar.prism.curie.getDataset(...
        args.dataset_source, args.dataset);
    args.score = ds_rec.score_file;
    args.rank = ds_rec.rank_file;
else    
    assert(is_ds_or_file(args.score), 'Score not specified');
    if isempty(args.rank)
        mortar.util.Message.debug(args.verbose, '#Rank file not specified, calculating ranks from scores')
        args.rank = score2rank(args.score);
    else
        assert(is_ds_or_file(args.rank), 'Rank not specified');
        mortar.util.Message.debug(args.verbose, '#Using precomputed ranks')
    end
end

% Annotate datasets if provided
if ~isempty(args.sig_meta)
    args.rank = annotate_ds(args.rank, args.sig_meta, 'dim', 'column');
end

% Validate queries
switch(lower(args.es_tail))
    case 'both'
        assert(is_gset_or_file(args.up),...
        'Up query expected for es_tail=%s', args.es_tail);    
        assert(is_gset_or_file(args.down),...
        'Down query expected for es_tail=%s', args.es_tail);    

    case 'up'
        assert(is_gset_or_file(args.up),...
        'Up query expected for es_tail=%s', args.es_tail);    

    case 'down'
        assert(is_gset_or_file(args.down),...
        'Down query expected for es_tail=%s', args.es_tail);    
end

% Update args
obj.setArgs(args);

end

function tf = is_struct_or_file(s)
tf = isstruct(s) || isfileexist(s, 'file');
end

function tf = is_ds_or_file(s)
tf = isds(s) || isfileexist(s, 'file');
end

function tf = is_gset_or_file(s)

tf = isgeneset(s) || ~isempty(uri_type(s)) || isfileexist(s, 'file');
end