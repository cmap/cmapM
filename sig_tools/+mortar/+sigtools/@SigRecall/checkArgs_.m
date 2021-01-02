function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;

%% ADD INPUT VALIDATION HERE
assert(~isempty(args.ds_list), 'ds_list cannot be empty');
assert(~isempty(args.sample_field), 'sample_field cannot be empty');
assert(~isempty(args.feature_field), 'feature_field cannot be empty');
args.sample_field = tokenize(args.sample_field, ',', true);
args.feature_field = tokenize(args.feature_field, ',', true);

obj.setArgs(args);

end