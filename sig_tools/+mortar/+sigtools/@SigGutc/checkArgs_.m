function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;
if isempty(args.rank) && isempty(args.score)
    build_ds = get_build_ds(args.build_id, args.feature_space);
    obj.setArg('rank', build_ds.rank);
    obj.setArg('score', build_ds.score);
end

% read updated args
args = obj.getArgs;

%% ADD INPUT VALIDATION HERE
% Either genesets or query results must be provided
if isequal(args.es_tail, 'both')
    assert((~isempty(args.up) && ~isempty(args.down)) ||...
        ~isempty(args.query_result),...
        'Either genesets or query result expected');
else
    
end

end