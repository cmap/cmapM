function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;

assert(isfileexist(args.ds, 'file') || isds(args.ds), 'Invalid input');
if isequal(args.read_mode, 'iterative')
    [~, ~, ext] = fileparts(args.ds);
    assert(strcmpi('.gctx', ext), 'GCTx file needed for iterative mode');
end
end