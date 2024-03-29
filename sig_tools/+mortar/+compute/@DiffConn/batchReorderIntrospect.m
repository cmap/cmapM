function res = batchReorderIntrospect(varargin)
% batchReorderIntrospect
%
%
%
% See also: splitIntrospect, reorderIntrospect

[args, help_flag] = getArgs(varargin{:});
if ~help_flag
    % process each cs file
    num_cs = length(args.cs_files);
    res = cell(num_cs, 1);
    % To lookup sensitivity by cp name and moa name
    cp_name_lut = mortar.containers.Dict(args.cp_sensitivity.cid);
    if ~isempty(args.moa_sensitivity)
        has_moa_sens = true;
        moa_name_lut = mortar.containers.Dict(args.moa_sensitivity.cid);
    else
        has_moa_sens = false;
    end
    
    gctwriter = ifelse(args.use_gctx, @mkgctx, @mkgct);
    
    parfor ii=1:num_cs
        this_cs = parse_gctx(args.cs_files{ii});
        this_cs_meta = gctmeta(this_cs);
        % update moa info if provided
        if ~isempty(args.moa_info)
            this_cs_meta = join_table(this_cs_meta, args.moa_info,...
                            args.pert_name_field, args.pert_name_field,...
                            '', '-666');
        end        
        % select matching cp_sens
        this_pert = {this_cs_meta.(args.pert_name_field)}';
        uniq_pert = unique(this_pert);
        % should be just one pert per matrix
        assert(isequal(length(uniq_pert), 1),...
            'The %s field should have unique values, found %d unique entries:%s', ...
            args.pert_name_field, length(uniq_pert), print_dlm_line(uniq_pert, 'dlm', ','));
        uniq_pert = uniq_pert{1};
        cp_sens_cidx = cp_name_lut(uniq_pert);
        assert(~isnan(cp_sens_cidx), 'Cp sensitivity not found for %s', uniq_pert);
        this_cp_sens = ds_slice(args.cp_sensitivity, 'cidx', cp_sens_cidx);
        
        dbg(1, '%d/%d %s', ii, num_cs, uniq_pert);
        % select matching moa_sens
        if has_moa_sens
            this_moa = {this_cs_meta.(args.moa_name_field)}';
            uniq_moa = unique(this_moa);
            assert(isequal(length(uniq_moa), 1),...
                'The %s field should have unique values, found %d unique entries:%s', ...
                args.moa_name_field, length(uniq_moa), print_dlm_line(uniq_moa, 'dlm', ','));
            uniq_moa = uniq_moa{1};
            uniq_moa_list = tokenize(uniq_moa, '|', true);
            moa_sens_cidx = moa_name_lut(uniq_moa_list);
            is_moa_sens_missing = isnan(moa_sens_cidx);
            if any(is_moa_sens_missing)
                warning('%d/%d MoA are missing sensitivity information, ignoring',...
                    nnz(is_moa_sens_missing), length(is_moa_sens_missing));
            end
            moa_sens_cidx = moa_sens_cidx(~is_moa_sens_missing);
            if ~isempty(moa_sens_cidx)
                this_moa_sens = ds_slice(args.moa_sensitivity, 'cidx', moa_sens_cidx);
            else
                this_moa_sens = [];
            end
        else
            this_moa_sens = [];
        end
        this_cs = mortar.compute.DiffConn.reorderIntrospect(this_cs, this_cp_sens,...
                                'moa_sensitivity', this_moa_sens,...
                                'cell_line_field', args.cell_line_field,...
                                'sens_agg_fun', args.sens_agg_fun,...
                                'sens_corr_metric', args.sens_corr_metric);
        if ~isempty(args.out)
            out_file = fullfile(args.out, sprintf('%s.gct', uniq_pert));
            res{ii} = gctwriter(out_file, this_cs);
        else
            res{ii} = this_cs;
        end

    end
end

end

function [args, help_flag] = getArgs(varargin)

pnames = {'cs_files';...
    'cp_sensitivity';...
    '--moa_sensitivity';...
    '--moa_info';...
    '--sig_id_field';...
    '--pert_name_field';...
    '--cell_line_field';...
    '--moa_name_field';...
    '--out';...
    '--use_gctx';...
    '--sens_agg_fun';...
    '--sens_corr_metric'};

defaults = {'';...
    '';...
    '';...
    '';...
    'sig_id';...
    'pert_iname';...
    'cell_id';...
    'moa';...
    '';...
    true;...
    'median';...
    'pearson'};

help_str = {'Cell array with paths to introspect files';...
    'GCT(x), A cell line x pert binary matrix indicating cell lines that are sensitive to each treatment';...
    'GCT(x), A cell line x moa matrix, with each cell line entry indicating the number of cps sharing the same MoA that impact the given cell line.';...
    'text table / struct, specifying pert to moa mapping, should contain pert_name_field and moa_name_field';...
    'Sig Id field';...
    'Pert name field';...
    'Cell line field';...
    'MoA name field';...
    'Output path, if not empty subsets are saved as GCT(x) files and their paths are returned';...
    'Save files as GCTX if true, GCTX if false';...
    'string, Aggregation function applied to generate the sensitivity vector';...
    'string, Correlation metric used to compare each column with the sensitivity vector'};

config = struct('name', pnames,...
    'default', defaults,...
    'help', help_str);
opt = struct('prog', mfilename, 'desc', '');

[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

% Validate inputs
assert(iscell(args.cs_files) || all(isfileexist(args.cs_files)),...
    'Required argument cs_files missing');
args.cs_files = parse_grp(args.cs_files);
is_cs_file_exist = isfileexist(args.cs_files);
assert(all(is_cs_file_exist), '%d/%d cs_files not found',...
    nnz(~is_cs_file_exist), length(is_cs_file_exist));
assert(isds(args.cp_sensitivity) || isfileexist(args.cp_sensitivity),...
    'cp_sensitivity file not found : %s', args.cp_sensitivity);
args.cp_sensitivity = parse_gctx(args.cp_sensitivity);
if ~isempty(args.moa_sensitivity)
    args.moa_sensitivity = parse_gctx(args.moa_sensitivity);
end

% Join pert info if provided, mainly to update moa membership
if ~isempty(args.moa_info)
    dbg(1, 'Joining metadata from pert_info');
    args.moa_info = parse_record(args.moa_info);
end

if ~isempty(args.out)
    mkdirnotexist(args.out);
end
end