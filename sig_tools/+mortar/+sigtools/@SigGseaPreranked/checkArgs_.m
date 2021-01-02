function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;

%% ADD INPUT VALIDATION HERE

assert(is_ds_or_file(args.score), 'Score not specified');
if isempty(args.rank)
    dbg(1, '!!! Rank file not specified, calculating ranks from scores. Use --rank to save time')
    args.score = parse_gctx(args.score, 'detect_numeric', false);
    args.rank = score2rank(args.score);
else
    assert(is_ds_or_file(args.rank), 'Rank not specified');
    dbg(args.verbose, '# Using pre-computed ranks')
end

%assert(is_struct_or_file(args.sig_meta), 'Signature metadata not specified');

% Either genesets or query results must be provided
if isequal(args.es_tail, 'both')
    assert((is_gset_or_file(args.up) && is_gset_or_file(args.down)),...
        'Both genesets expected');
elseif isequal(args.es_tail, 'up')
    assert(is_gset_or_file(args.up),...
        'Up geneset expected');
else
    assert(is_gset_or_file(args.down),...
        'Down geneset expected');    
end

% % ncs grouping variable 
% if ~isempty(args.ncs_group)
%     ncs_group = tokenize(args.ncs_group, ',', true);
%     obj.setArg('ncs_group', ncs_group);
% end

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