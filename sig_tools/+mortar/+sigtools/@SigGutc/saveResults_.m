function saveResults_(obj, out_path)
required_fields = {'args', 'query_result', 'gutc_result'};
res = obj.getResults;
args = obj.getArgs;

ismem = isfield(res, required_fields);
if ~all(ismem)
    disp(required_fields(~ismem));
    error('Some required fields not specified');
end

gutc_fields = {'args',...
    'cs_sig', 'ns_sig', 'ps_sig', 'ns_rpt',...
    'ns_pert_cell', 'ps_pert_cell',...
    'ns_pert_summary', 'ps_pert_summary',...
    'ns_pcl_cell', 'ps_pcl_cell',...
    'ns_pcl_summary', 'ps_pcl_summary'};

tf = isfield(res.gutc_result, gutc_fields);
if ~all(tf)
    disp(gutc_fields(~tf));
    error('Some gutc fields not specified');
end

% Save matrices
if args.save_matrices
    saveMatrices(res, out_path);
end

% save digest folders
if args.save_digests
    % TODO: switch to using mortar.compute.Gutc.saveGutcARF
    saveResultsPerQuery(res, out_path, args.is_matched);
end

end

function saveResultsPerQuery(res, out_path, is_matched)
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
[query_id, iquery_id] = getcls({query_info.query_id});
nquery = length(query_id);

if isfield(query_info, 'cell_id')
    % rename cell_id to query_cell_id, for CLUE app
    query_info = mvfield(query_info, 'cell_id', 'query_cell_id');
    has_cell_id = true;
else
    has_cell_id = false;
    dbg(1, 'query_info does not have cell_id field, ignoring');
end

% Build la table
[~, uidx] = unique(iquery_id, 'stable');
index = query_info(uidx);
index = rmfield(index, 'cid');
index = orderfields(index, orderas(fieldnames(index), 'query_id'));
if is_matched && has_cell_id
    % generate query_cell_ids field with list of cell lines used
    index = rmfield(index, 'query_cell_id');
    [~, query_cell_ids] = group2cell({query_info.query_cell_id}', iquery_id);
    index = setarrayfield(index, [], 'query_cell_ids', query_cell_ids);
end

% % index = query_info for umatched queries
% % for matched-mode, index has one entry per query group (by query_id)
% index = gctmeta(ds_slice(res.gutc_result.ps_pert_cell, 'cid', query_id), 'column');
% index = mvfield(index, 'cid', 'query_id');
% location of per-query results
url = cell(nquery, 1);

% Save each query result in a subfolder
arf_path = fullfile(out_path, 'arfs');
for ii=1:nquery
    [~, sub_folder] = validate_path(upper(query_id{ii}), '_');
    this_out = fullfile(arf_path, sub_folder);
    if ~mortar.util.File.isfile(this_out, 'dir')
        mkdir(this_out);
    end
    
    url{ii} = path_relative_to(arf_path, this_out);
    
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
    mktbl(fullfile(this_out, 'query_info.txt'), this_query_info);
    
    % Sig level results
    if ~isempty(res.gutc_result.ps_sig)
        this_sig = ds_strip_meta(ds_slice(res.gutc_result.ps_sig, 'cidx',  ii));
        gctwriter(fullfile(this_out,'sig.gct'), this_sig, 'appenddim', false, 'precision', num_digits);
    end
    
    if ~isempty(res.gutc_result.ps_pert_cell)
        % PERT level matrices
        % pert_id cell
        % filter shRNA results
        pc_rid = res.gutc_result.ps_pert_cell.rid(~strcmp(ds_get_meta(res.gutc_result.ps_pert_cell,'row','pert_type'),'trt_sh'));
        this_pc = ds_slice(res.gutc_result.ps_pert_cell, 'cidx', ii, 'rid', pc_rid);
        this_pc = ds_nan_to_val(this_pc, nan_val);
        column_info = gctmeta(this_pc, 'column');
        % rename index field to match the index.txt
        column_info = mvfield(column_info, 'cid', 'query_id');
        this_pc = ds_strip_meta(this_pc);
        gctwriter(fullfile(this_out,'pert_id_cell.gct'), this_pc, 'appenddim', false, 'precision', num_digits);
        mktbl(fullfile(this_out, 'column_info.txt'), column_info);
    end
    
    % pert_id summary
    if ~isempty(res.gutc_result.ps_pert_summary)
        this_p = ds_strip_meta(ds_slice(res.gutc_result.ps_pert_summary, 'cidx', ii));
        gctwriter(fullfile(this_out,'pert_id_summary.gct'), this_p, 'appenddim', false, 'precision', num_digits);
    end
    
    % PCL level matrices [nPCL x nCell] x 1 and nPCL x 1
    if ~isempty(res.gutc_result.ps_pcl_cell) && ~isempty(res.gutc_result.ps_pcl_summary)
        this_pcl_cell = ds_strip_meta(ds_slice(res.gutc_result.ps_pcl_cell, 'cidx',  ii));
        this_pcl_cell = ds_nan_to_val(this_pcl_cell, nan_val);
        this_pcl_summary = ds_strip_meta(ds_slice(res.gutc_result.ps_pcl_summary, 'cidx', ii));
        gctwriter(fullfile(this_out, 'pcl_summary.gct'), this_pcl_summary, 'appenddim', false, 'precision', num_digits);
        gctwriter(fullfile(this_out, 'pcl_cell.gct'), this_pcl_cell, 'appenddim', false, 'precision', num_digits);
    end
end

[index.url] = url{:};
% create the index file
mktbl(fullfile(arf_path, 'index.txt'), index)

end

function matrix_out = saveMatrices(res, out_path)
%% save results as matrices
matrix_out = fullfile(out_path, 'matrices');
if ~isdirexist(matrix_out)
    mkdir(matrix_out);
end

mortar.compute.Connectivity.saveResult(res.query_result,...
    fullfile(matrix_out, 'query'));
mortar.compute.Gutc.saveMultiUnmatchedGutc(res.gutc_result,...
    fullfile(matrix_out, 'gutc'), true);
end
