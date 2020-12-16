function saveGutcARF(gutc_path, out_path, query_info, make_arf_by_pert, add_query_field)
% saveGutcARF Save analysis report files for GUTC results.
% saveGutcARF(gutc_path, out_path, query_info, make_arf_by_pert, add_query_field)
% Generates one ARF folder per query if make_arf_by_pert is false else
% generates one ARF per unique pert_id in query_info

res = loadData(gutc_path, query_info);

if ~isdirexist(out_path)
    mkdir(out_path);
end

% replace nan values with alternative
nan_val = nan;
% numeric precision for GCT files
num_digits = 2;
gctwriter=@mkgct;

% Queries
%if isstruct(res.query_result) && all(isfield(res.query_result, {'uptag', 'dntag'}))
%    mkgmt(fullfile(out_path, 'query_up.gmt'), res.query_result.uptag);
%    mkgmt(fullfile(out_path, 'query_dn.gmt'), res.query_result.dntag);
%end

%nquery = size(res.gutc_result.ps_pert_cell.mat, 2);
%query_id = res.gutc_result.ps_pert_cell.cid;
% re-org sig level data
%cs = ds_slice(res.gutc_result.cs_sig, 'rid', res.gutc_result.ns_sig.rid);
%assert(isequal(res.gutc_result.ns_sig.rid,...
%               res.gutc_result.ps_sig.rid),...
%               'Row order mismatch NS and PS');

query_info = res.gutc_result.query_info;
if make_arf_by_pert
    has_pert_id = isfield(query_info, 'pert_id');
    assert(has_pert_id, 'pert_id field not found. Cannot generate per-pert ARFs');
    [query_id, iquery_id] = getcls({query_info.pert_id});
    [~, uidx] = unique(iquery_id, 'stable');
    pert_fields = {'pert_id', 'pert_iname', 'pert_type',...
        'moa', 'target_gene', 'pert_icollection'};
    if ~isempty(add_query_field)
        pert_fields = union(pert_fields, add_query_field, 'stable');
    end
    keep_fields = intersect(pert_fields, fieldnames(query_info), 'stable');
    index = keepfield(query_info(uidx), keep_fields);
else
    [query_id, iquery_id] = getcls({query_info.query_id});
    index = query_info;
end
nquery = length(query_id);

% location of per-query results
url = cell(nquery, 1);

% Save each query result in a subfolder
for ii=1:nquery
    [~, sub_folder] = validate_path(upper(query_id{ii}), '_');
    this_out = fullfile(out_path, sub_folder);
    if ~mortar.util.File.isfile(this_out, 'dir')
        mkdir(this_out);
    end
    
    url{ii} = path_relative_to(out_path, this_out);
    
    % % SIG level matrix
    % sig = mkgctstruct([res.gutc_result.ns_sig.mat(:, ii),...
    %                    cs.mat(:, ii)],...
    %     'rid', cs.rid,...
    %     'cid', {'norm_score', 'raw_score'},...
    %     'chd', {'query_id'},...
    %     'cdesc', [res.gutc_result.ns_sig.cid(ii);...
    %               cs.cid(ii)]);
    
    % gctwriter(fullfile(this_out, 'sig.gct'), sig,...
    %           'appenddim', false, 'precision', num_digits);
    
    % Query annotations
    this_query = iquery_id == ii;
    this_query_info = query_info(this_query);
    this_query_info = setarrayfield(this_query_info, [], 'url', url(ii));
    %this_query_info.url = url{ii};
    mktbl(fullfile(this_out, 'query_info.txt'), this_query_info);
    
    % PERT level matrices
    % pert_id cell
    % filter shRNA results
    pc_rid = res.gutc_result.ps_pert_cell.rid(~strcmp(ds_get_meta(res.gutc_result.ps_pert_cell,'row','pert_type'),'trt_sh'));
    this_pc = ds_slice(res.gutc_result.ps_pert_cell, 'cidx', this_query, 'rid', pc_rid);
    this_pc = ds_nan_to_val(this_pc, nan_val);
    %     column_info = gctmeta(this_pc, 'column');
    %     % rename index field to match the index.txt
    %     column_info = mvfield(column_info, 'cid', 'query_id');
    %     % Add url field
    %     column_info.url = url{ii};
    %
    this_pc = ds_strip_meta(this_pc);
    gctwriter(fullfile(this_out,'pert_id_cell.gct'), this_pc, 'appenddim', false, 'precision', num_digits);
    %     mktbl(fullfile(this_out, 'column_info.txt'), column_info);
    %
    % pert_id summary
    this_p = ds_strip_meta(ds_slice(res.gutc_result.ps_pert_summary, 'cidx', this_query));
    gctwriter(fullfile(this_out,'pert_id_summary.gct'), this_p, 'appenddim', false, 'precision', num_digits);
    
    %     % pert_iname cell
    %     tnc_rid = res.gutc_result.tnc.rid(~strcmp(ds_get_meta(res.gutc_result.tnc,'row','pert_type'),'trt_sh'));
    %     this_tnc = ds_strip_meta(ds_slice(res.gutc_result.tnc, 'cidx', ii, 'rid', tnc_rid));
    %     this_tnc = ds_nan_to_val(this_tnc, nan_val);
    %     gctwriter(fullfile(this_out,'pert_iname_cell.gct'), this_tnc, 'appenddim', false, 'precision', num_digits);
    %
    %     % pert_iname summary
    %     this_tn = ds_strip_meta(ds_slice(res.gutc_result.tn, 'cidx', ii));
    %     gctwriter(fullfile(this_out,'pert_iname_summary.gct'), this_tn, 'appenddim', false, 'precision', num_digits);
    
    % PCL level matrices [nPCL x nCell] x 1 and nPCL x 1
    this_pcl_cell = ds_strip_meta(ds_slice(res.gutc_result.ps_pcl_cell, 'cidx',  this_query));
    this_pcl_cell = ds_nan_to_val(this_pcl_cell, nan_val);
    this_pcl_summary = ds_strip_meta(ds_slice(res.gutc_result.ps_pcl_summary, 'cidx', this_query));
    gctwriter(fullfile(this_out, 'pcl_summary.gct'), this_pcl_summary, 'appenddim', false, 'precision', num_digits);
    gctwriter(fullfile(this_out, 'pcl_cell.gct'), this_pcl_cell, 'appenddim', false, 'precision', num_digits);
end

[index.url] = url{:};
% create the index file
mktbl(fullfile(out_path, 'index.txt'), index)

end


function res = loadData(gutc_path, query_info)

res = struct('args', '',...
    'gutc_result', '');

% PS matrices

gutc_result_fields = {'ps_pert_cell', 'ps_pert_summary', 'ps_pcl_cell', 'ps_pcl_summary'};
gutc_matrix_files = {'ps_pert_cell.gctx', 'ps_pert_summary.gctx', 'ps_pcl_cell.gctx', 'ps_pcl_summary.gctx'};
% gutc matrices
gutc_matrix_path = fullfile(gutc_path, 'matrices', 'gutc');
assert(isdirexist(gutc_matrix_path), 'Gutc matrices not found at %s',...
    gutc_matrix_path);
nmatrix = length(gutc_matrix_files);
for ii=1:nmatrix
    this_file = fullfile(gutc_matrix_path, gutc_matrix_files{ii});
    assert(isfileexist(this_file), 'Gutc matrix file %s not found at %s',...
        gutc_matrix_files{ii}, gutc_matrix_path);
    [res.gutc_result.(gutc_result_fields{ii})] = parse_gctx(this_file);
end

% query info
if ~isempty(query_info)
    % override metadata save with GUTC results
    query_info = parse_record(query_info);
    % try annotating a matrix
    x = annotate_ds(res.gutc_result.ps_pert_cell, query_info, 'append', false);
    res.gutc_result.query_info  = gctmeta(x);
    res.gutc_result.query_info = mvfield(res.gutc_result.query_info,...
        'cid', 'query_id');
else
    % use GUTC metadata
    query_info_file = fullfile(gutc_matrix_path, 'query_info.txt');
    if isfileexist(query_info_file)
        query_info = parse_record(query_info_file);
        % try annotating a matrix
        x = annotate_ds(res.gutc_result.ps_pert_cell, query_info, 'append', false);
        res.gutc_result.query_info  = gctmeta(x);
        res.gutc_result.query_info = mvfield(res.gutc_result.query_info, 'cid', 'query_id');
    else
        warning('query_info not found, using matrix metadata');
        res.gutc_result.query_info = gctmeta(res.gutc_result.ps_pert_cell);
        res.gutc_result.query_info = mvfield(res.gutc_result.query_info,...
            'cid', 'query_id');
    end
end
% rename cell_id to query_cell_id
if isfield(res.gutc_result.query_info, 'cell_id')
    res.gutc_result.query_info = mvfield(res.gutc_result.query_info,...
        'cell_id', 'query_cell_id');
end

end