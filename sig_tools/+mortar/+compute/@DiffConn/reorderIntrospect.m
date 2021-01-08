function cs = reorderIntrospect(varargin)
% reorderIntrospect Reorder Introspect based on sensitivity
% new_cs = reorderIntrospect(cs, cp_sensitivity, varargin)
%
% Required arguments:
% cs : GCT(x), introspect matrix of connectivity scores 
%               (cell line x cell line) for one cp treatment. Should be
%               annotated, and the 'cell_id' field is required
% cp_sensitivity : GCT(x), A cell line x 1 binary matrix indicating
%                cell lines that are sensitive to treatment.
%
% Optional arguments:
% --moa_sensitivity : GCT(x), A cell line x 1 matrix, with
%                   each cell line entry indicating the number of cps
%                   sharing the same MoA that impact the given cell line.
% --cell_line_field : string, Cell line annotation field of cs should match
%                   row-ids of cp_sensitivity and moa_sensitivity
% --sens_agg_fun : string, Aggregation function applied to generate the
%                  sensitivity vector
% --sens_corr_metric : string, Correlation metric used to compare each
%                      column with the sensitivity vector
%
% Returns a reordered dataset with the following embedded meta-data fields
% 'cp_sens' : binary indicator variable that is 1 if the cell line is
%             sensitive, 0 is not.
% 'moa_sens_*' : one field per column in the moa_sensitivity matrix,
%               specifying the number of MoA members that impact each cell
%               line
% 'sens_vec' : The aggregate sensitivity vector, calculated by aggregating
%              the data for sensitivite cell lines
% 'corr_sens' : Correlation of each cell line to the aggregate sensitivity
%               vector

[args, help_flag] = getArgs(varargin{:});

if ~help_flag
        
    if ~isempty(args.moa_sensitivity)
        has_moa_sensitivity = true;
    else
        has_moa_sensitivity = false;
    end
    
    cs_meta = gctmeta(args.cs);    
    cs_cell_line = {cs_meta.(args.cell_line_field)}';
    
    % validate inputs
    % cs should have the args.cell_line_field
    assert(isfield(cs_meta, args.cell_line_field),...
        sprintf('CS column metadata missing required field:%s', args.cell_line_field));
    % cp_sensitivity should be a column vector
    assert(isequal(length(args.cp_sensitivity.cid), 1),...
        sprintf('CP_SENSITIVITY should have 1 column found %d', length(args.cp_sensitivity.cid)));
    
    [cmn_cp_sens_line, idx_cs1, idx_cp_sens] = intersect(cs_cell_line, args.cp_sensitivity.rid);
    
    num_cell_line = length(cs_cell_line);
    num_cp_sens = length(cmn_cp_sens_line);
    dbg(1, 'CP sensitivity found for %d / %d lines', num_cp_sens, num_cell_line);
            
    % Join cp and MoA Sensitivity
    cp_sens_tbl = struct(args.cell_line_field, args.cp_sensitivity.rid, 'cp_sens', num2cell(args.cp_sensitivity.mat));
    cs_meta = join_table(cs_meta, cp_sens_tbl, args.cell_line_field, args.cell_line_field, '', single(-666));
    
    if has_moa_sensitivity
        [cmn_moa_sens_line, idx_cs2, idx_moa_sens] = intersect(cs_cell_line, args.moa_sensitivity.rid);
        num_moa_sens = length(cmn_moa_sens_line);
        dbg(1, 'MoA sensitivity found for %d / %d lines', num_moa_sens, num_cell_line);
        % rename columns
        args.moa_sensitivity.cid = strcat('moa_sens_', lower(args.moa_sensitivity.cid));
        moa_sens_tbl = gct2tbl(ds_strip_meta(args.moa_sensitivity));
        cs_meta = join_table(cs_meta, moa_sens_tbl, args.cell_line_field, 'rid', '', single(-666));
    else
        dbg(1, 'MoA sensitivity not provided, skipping');
    end
    
    % compute correlation to sens vector for reordering the cell lines
    this_sens = [cs_meta.cp_sens]';
    sens_idx = find(this_sens>0);
    [cc_sens, sens_vec] = mortar.compute.DiffConn.corrMatrixToGroup(args.cs.mat, sens_idx, 'median', 'pearson');
    cs_meta = setarrayfield(cs_meta, [], {'corr_sens', 'sens_vec'}, cc_sens, sens_vec);
    cs = annotate_ds(args.cs, cs_meta, 'append', false);
    cs = annotate_ds(cs, cs_meta, 'dim', 'row', 'append', false);
    [srt, srt_idx] = sorton([this_sens, cc_sens], [1, 2], 1, {'descend', 'descend'});
    cs = ds_slice(cs, 'cidx', srt_idx, 'ridx', srt_idx);
    
end
end

function [args, help_flag] = getArgs(varargin)
pnames = {'cs';...
    'cp_sensitivity';...
    '--moa_sensitivity';...
    '--cell_line_field';...
    '--sens_agg_fun';...
    '--sens_corr_metric'};

defaults = {'';...
    '';...
    '';...
    'cell_id';...
    'median';...
    'pearson'};

help_str = { 'GCT(x), introspect matrix of connectivity scores (cell line x cell line) for one cp treatment. Should be annotated, and the cell_line_field field is required';...
    'GCT(x), A cell line x 1 binary matrix indicating cell lines that are sensitive to treatment.';...
    'GCT(x), A cell line x 1 matrix, with each cell line entry indicating the number of cps sharing the same MoA that impact the given cell line.';...
    'string, Cell line annotation field of cs should match row-ids of cp_sensitivity and moa_sensitivity';...
    'string, Aggregation function applied to generate the sensitivity vector';...
    'string, Correlation metric used to compare each column with the sensitivity vector'};

config = struct('name', pnames,...
    'default', defaults,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Make Introspect heatmap');

[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

assert(isds(args.cs) || isfileexist(args.cs), 'cs file not found : %s', args.cs);
assert(isds(args.cp_sensitivity) || isfileexist(args.cp_sensitivity), 'cp_sensitivity file not found : %s', args.cp_sensitivity);

args.cs = parse_gctx(args.cs);
args.cp_sensitivity = parse_gctx(args.cp_sensitivity);
if ~isempty(args.moa_sensitivity)
    args.moa_sensitivity = parse_gctx(args.moa_sensitivity);
end

end
