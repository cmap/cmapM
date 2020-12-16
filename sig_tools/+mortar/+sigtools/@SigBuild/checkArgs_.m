function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;

%% ADD INPUT VALIDATION HERE
% assert(~isempty(args.ds), 'Dataset not specified');
assert(isdirexist(args.brew_path), 'Brew path not found : %s', args.brew_path);
assert(~isempty(args.brew_list), 'Brew list not specified');
assert(~isempty(args.brew_group), 'Brew group not specified');
assert(~isempty(args.brew_root), 'Brew root not specified');

end