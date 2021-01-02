function runAnalysis_(obj, varargin)
% extract subset from dataset
    args = obj.getArgs;    
    obj.res_ = struct('args', args, 'ds', mkgctstruct);
    if isempty(args.rid) && ~strcmpi(args.row_space, 'custom')        
        rid = mortar.common.Spaces.probe(args.row_space).asCell;
    else
        rid = args.rid;
    end
    obj.res_.ds = parse_gctx(args.ds,...
        'cid', args.cid,...
        'rid', rid, ...
        'ignore_missing', args.ignore_missing);
    if ~isempty(args.row_meta)
        obj.res_.ds = annotate_ds(obj.res_.ds, args.row_meta,...
                        'dim', 'row', 'skipmissing', true);
    end
    
    if ~isempty(args.col_meta)
        obj.res_.ds = annotate_ds(obj.res_.ds, args.col_meta,...
                        'dim', 'column', 'skipmissing', true);
    end
    
end

