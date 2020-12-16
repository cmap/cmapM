function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;

%% ADD INPUT VALIDATION HERE
assert(~isempty(args.sig_score)||~isempty(args.sig_connectivity),...
    'Sig Score or connectivity must be specified');

end