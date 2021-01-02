function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;

assert(~isempty(args.ds), 'Dataset not specified');
assert(~isempty(args.model), 'Model not specified.');

if ~isds(args.model) || isfileexist(args.model)
    [~,~,ext] = fileparts(args.model);
    switch ext
        case '.gctx'
            model = parse_gctx(args.model, 'annot_only', 1);
        case '.gct'
            model = parse_gct(args.model, 'annot_only', 1, 'verbose', 0);
        case '.mat'
            load(args.model);
        otherwise
            error('Invalid model filetype');
    end
else
    error('No model given');
end

assert(~isempty(model.cdesc{1,1}), 'No landmark grp path included in model');

metadata = parse_gctx(args.ds, 'annot_only', 1);
lmspace = model.cid(2:end);

cmn = intersect_ord(metadata.rid, lmspace);
if ~isequal(length(cmn), length(lmspace))
    disp(setdiff(lmspace, cmn));
    error('Some landmarks not found in dataset');
end

end