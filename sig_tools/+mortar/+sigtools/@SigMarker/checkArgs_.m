function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;
assert(~isempty(args.ds), 'Dataset not specified');
assert(~isempty(args.phenotype), 'Phenotype definition not specified');
if ~isempty(args.feature_id)
    assert(mortar.util.File.isfile(args.feature_id) || iscell(args.feature_id),...
        'Feature id not a file or cell array');    
else
    assert(strcmp('all', args.feature_space)|...
        mortar.common.Spaces.probe_space.isKey(args.feature_space),...
        'Feature space %s not recognized', args.feature_space);
end
end