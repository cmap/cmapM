function subsets = splitIntrospect(varargin)
% splitIntrospect Extract subsets from an introspect matrix
%   subsets = splitIntrospect(CS, CS_META, varargin)
% cs : GCT(x) file or structure, 
% cs_meta : Metadata for CS
% --pert_name : GRP, list of perturbagens to include, if empty all
%            perturbagens are included. The cell_line_field specifies the
%            field used to match the values
% --cell_line : GRP, list of cell lines to include. The cell_line_field 
%                  specifies the field used to match the values
% --out : Output folder. GCT(x) files are generated and paths to the 
%            output files are returned. Otherwise a cell array of GCT
%            structures are returned.
% --use_gctx : Save as GCTX if true
% --sig_id_field : string, field used to lookup signature ids. Default is
%               'sig_id'
% --pert_name_field : string, field used to lookup perturbagen names. Default
%               is 'pert_iname'
% --cell_line_field : string, field used to lookup cell lines. Default is
%               'cell_id'
%

[args, help_flag] = getArgs(varargin{:});

if (~help_flag)
    sig_id_field = args.sig_id_field;
    pert_name_field = args.pert_name_field;
    cell_line_field = args.cell_line_field;
    
    cs_meta = parse_record(args.cs_meta);
    
    req_fn = {sig_id_field, pert_name_field, cell_line_field};
    assert(has_required_fields(cs_meta, req_fn),...
        'cs_col_meta is missing required fields')
    
    if ~isempty(args.pert_name)
        pert_name = parse_grp(args.pert_name);
        keep_pert = ismember({cs_meta.(pert_name_field)}', pert_name);
        dbg(1, 'Filtering signatures to pert_name list, found %d/%d matches',...
            nnz(keep_pert), length(keep_pert));
        cs_meta = cs_meta(keep_pert);
    end
    
    if ~isempty(args.cell_line)
        cell_line= parse_grp(args.cell_line);
        keep_cell = ismember({cs_meta.(cell_line_field)}', cell_line);
        dbg(1, 'Filtering signatures to cell_line list, found %d/%d matches',...
            nnz(keep_cell), length(keep_cell));
        cs_meta = cs_meta(keep_cell);
    end
        
    [cp_gp, cp_gpn, cp_gpi] = get_groupvar(cs_meta, [], pert_name_field);
    num_cp = length(cp_gpn);
    subsets = cell(num_cp, 1);
    gctwriter = ifelse(args.use_gctx, @mkgctx, @mkgct);
    
    parfor ii=1:num_cp
        this_cp = cp_gpn{ii};
        cs_idx = cp_gpi == ii;
        this_subset = cs_meta(cs_idx);
        this_sig_id = {this_subset.(sig_id_field)}';
        dbg(1, '%d/%d %s', ii, num_cp, this_cp);
        
        % subset of CS matrix, for corr_sens computation
        this_cs = parse_gctx(args.cs, 'cid', this_sig_id);
        this_cs = ds_slice(this_cs, 'rid', this_sig_id);
        this_cs = annotate_ds(this_cs, cs_meta, 'append', false);
        this_cs = annotate_ds(this_cs, cs_meta, 'dim', 'row', 'append', false);

        if ~isempty(args.out)
            out_file = fullfile(args.out, sprintf('%s.gct', this_cp));
            subsets{ii} = gctwriter(out_file, this_cs);
        else
            subsets{ii} = this_cs;            
        end
    end
end

end

function [args, help_flag] = getArgs(varargin)
pnames = {'cs';...
    'cs_meta';...
    '--sig_id_field';...
    '--pert_name_field';...
    '--cell_line_field';...
    '--out';...
    '--pert_name';...
    '--cell_line';...
    '--use_gctx'};

defaults = {'';...
    '';...
    'sig_id';...
    'pert_iname';...
    'cell_id';...
    '';...
    '';...
    '';...
    true};

help_str = {'Introspect matrix';...
    'Introspect metadata';...
    'Sig Id field';...
    'Pert name field';...
    'Cell line field';...
    'Output path, if not empty subsets are saved as GCT(x) files and their paths are returned';...
    'List of pert names to include';...
    'List of cell lines to include';...
    'Save files as GCTX if true, GCTX if false'};

config = struct('name', pnames,...
    'default', defaults,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', 'Split Introspect matrix');

[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

if ~isempty(args.out)
    mkdirnotexist(args.out);
end

end