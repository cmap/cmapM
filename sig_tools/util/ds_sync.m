function [ds1, ds2] = ds_sync(varargin)
% DS_SYNC Match two datasets by row and column metadata

[help_flag, args] = getArgs(varargin{:});
if ~help_flag
    % slice to shared features
    ds1 = parse_gctx(args.ds1);
    ds2 = parse_gctx(args.ds2);
    
    ds1_row_names = get_groupvar(gctmeta(ds1,'row'), [], args.row_match_field);
    ds2_row_names = get_groupvar(gctmeta(ds2, 'row'), [], args.row_match_field);
    [cmn_rows, ira, irb] = intersect(ds1_row_names, ds2_row_names, 'stable');
    
    ds1_col_names = get_groupvar(gctmeta(ds1, 'column'), [], args.col_match_field);
    ds2_col_names = get_groupvar(gctmeta(ds2, 'column'), [], args.col_match_field);
    
    [cmn_cols, ica, icb] = intersect(ds1_col_names, ds2_col_names, 'stable');
    ds1 = ds_slice(ds1, 'rid', ds1.rid(ira), 'cid', ds1.cid(ica));
    ds2 = ds_slice(ds2, 'rid', ds2.rid(irb), 'cid', ds2.cid(icb));
end

end

function [help_flag, args] = getArgs(varargin)
config = struct('name', {'ds1'; 'ds2'; '--row_match_field'; '--col_match_field'},...
    'default', {''; ''; 'rid'; 'cid'},...
    'help', {'Dataset 1'; 'Dataset 2';
    'Row metadata field to match'; 'Column metadata field to match'});
opt = struct('prog', mfilename, 'desc', 'Synchronize two datasets');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
if ~help_flag
    assert(~isempty(args.ds1), 'Dataset1 not specified')
    assert(~isempty(args.ds2), 'Dataset2 not specified')
    assert(~isempty(args.row_match_field), 'row_match_field not specified')
    assert(~isempty(args.col_match_field), 'col_match_field not specified')
end

end