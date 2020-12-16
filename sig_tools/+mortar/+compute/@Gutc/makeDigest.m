function makeDigest(varargin)   
% makeDigest

[args, help_flag] = get_args(varargin{:});
import mortar.util.Message
import mortar.compute.Gutc

if ~help_flag      
    % read gutc datasets
    if mortar.util.File.isfile(args.gutc_path, 'dir')
        ds = readGutcDatasets(args.gutc_path, args);
    else
        error('GUTC path not found %s', args.gutc_path)
    end    
    % generate tables and index
    Gutc.createDigestTables(ds, args.out_path, args);    
end

end

function all_ds = readGutcDatasets(gutc_path, args)
    % read per-cell and summly matrices
    pert_file = fullfile(gutc_path, 'pert.gctx');
    pert_cell_file = fullfile(gutc_path, 'pert_cell.gctx');
    assert(mortar.util.File.isfile(pert_file), '%s not found', pert_file);
    assert(mortar.util.File.isfile(pert_cell_file), '%s not found', pert_cell_file);
    pert_ds = parse_gctx(pert_file);
    pert_cell_ds = parse_gctx(pert_cell_file); 
    
   % append column annotations if provided
    if ~isempty(args.col_meta)
        col_meta = parse_tbl(args.col_meta, 'outfmt', 'record');
        keep_fn = {args.col_keyfield, 'pert_id', 'pert_iname', 'pert_type', 'cell_id', ...
                   'pert_idose', 'pert_itime'};
        col_meta = keepfield(col_meta, intersect(fieldnames(col_meta), ...
                                                 keep_fn));
        pert_ds = annotate_ds(pert_ds, col_meta, 'keyfield', args.col_keyfield);
        pert_cell_ds = annotate_ds(pert_cell_ds, col_meta, 'keyfield', args.col_keyfield);
    end
    
    % fix cell_id of summly
    pert_ds = ds_add_meta(pert_ds, 'row', 'cell_id', 'summary');
 
    % merge rows
    all_ds = merge_two(pert_ds, pert_cell_ds);
    
    % keep only core pert_id, cell_id and pert types 
    core_pert_id = pert_ds.rid;
    core_cell_id = union('summary', mortar.common.Spaces.cell('lincs_core').asCell);
    core_pert_type = mortar.common.Spaces.pert_type('digest').asCell;
    
    pert_id = ds_get_meta(all_ds, 'row', 'pert_id');
    pert_type = ds_get_meta(all_ds, 'row', 'pert_type');
    cell_id = ds_get_meta(all_ds, 'row', 'cell_id');    
    keep_rid = all_ds.rid(ismember(pert_id, core_pert_id) &...
                          ismember(cell_id, core_cell_id) &...
                          ismember(pert_type, core_pert_type));
                      
    all_ds = ds_slice(all_ds, 'rid', keep_rid);
    
    % cast to wide format npert x ncell*nquery
    all_ds = mortar.compute.Gutc.castDSToWide(all_ds, 'pert_id', 'cell_id');
    if any(strcmp('dup_cell_id', all_ds.chd))
        all_ds = ds_mv_meta(all_ds, 'column', 'dup_cell_id', 'ts_cell_id');
    end
end


function [args, help_flag] = get_args(varargin)

    ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
    opt = struct('prog', mfilename, 'desc', 'Compute GUTC in unmatched mode', 'undef_action', 'ignore');
    [args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

    % sanity checks

end
