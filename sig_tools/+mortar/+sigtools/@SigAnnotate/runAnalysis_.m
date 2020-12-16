function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)
res = struct('args', args,...
    'row_meta', [],...
    'column_meta', [],...
    'ds', mkgctstruct,...
    'is_updated', false);

update_row_meta = ~isempty(args.row_meta);
update_column_meta = ~isempty(args.column_meta);

if ~update_row_meta && ~update_column_meta
     % extract metadata
     dbg(1, '## Extracting Meta data');
    ds = parse_gctx(args.ds, 'annot_only', true);
    res.row_meta = gctmeta(ds, 'row');
    res.column_meta = gctmeta(ds, 'column');
else
    res.is_updated = true;
    % update metadata
    res.ds = parse_gctx(args.ds);
    if update_row_meta
        res.ds = annotate_ds(res.ds, args.row_meta, 'dim', 'row');
    end
    if update_column_meta
        res.ds = annotate_ds(res.ds, args.column_meta, 'dim', 'column');
    end
end

res.is_strip = true;
switch args.strip_matrix
    case 'both'
        ds = parse_gctx(args.ds);
        res.ds_strip = ds_strip_meta(ds);
    case 'row'
        ds = parse_gctx(args.ds);
        res.ds_strip = ds_delete_meta(ds, 'row', ds.rhd);
    case 'column'
        ds = parse_gctx(args.ds);
        res.ds_strip = ds_delete_meta(ds, 'column', ds.chd);
    otherwise
        res.is_strip = false;
end

end

function [args, help_flag] = getArgs(varargin)
% validate inputs
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    assert(~isempty(args.ds), 'Dataset not specified');
end
end
