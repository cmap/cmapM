function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;

assert(~isempty(args.ds), 'Dataset not specified');
assert(~isempty(args.grp_landmark) || ~isfileexist(args.grp_landmark), 'Landmarks not specified.');

lmspace = parse_grp(args.grp_landmark);
if ~isempty(args.dependents)
    dependents = parse_grp(args.dependents);
    rid = union(lmspace, dependents);
else
    rid = '';
end

metadata = parse_gctx(args.ds, 'annot_only', 1, 'rid', rid, 'cid', args.cid);

cmn = intersect_ord(metadata.rid, lmspace);
if ~isequal(length(cmn), length(lmspace))
    disp(setdiff(lmspace, cmn));
    error('Some landmarks not found in dataset');
end

if isempty(setdiff(metadata.rid, lmspace))
    error('No dependent features in dataset to predict');
end


end