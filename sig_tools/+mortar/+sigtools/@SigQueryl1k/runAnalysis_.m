function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)
% Main function
import mortar.util.Message

%% Read and validate signature annotations
Message.log(args.verbose, '# Reading Signature annotations');
sig_meta = readSigMeta(args.sig_meta, args.ncs_group, args.exemplar_field);

%% Run Cmap Query
Message.log(args.verbose, '# Running Cmap query');
query_result = mortar.compute.Connectivity.runCmapQuery(...
    'score', args.score, ...
    'rank', args.rank, ...
    'uptag', args.up,...
    'dntag', args.down,...
    'es_tail', args.es_tail,...
    'metric', args.metric,...
    'max_col', args.max_col);

%% Normalize connectivity scores
Message.log(args.verbose, '# Normalizing query');
rid_ref = {sig_meta([sig_meta.is_ncs_sig]'>0).sig_id}';
[ncs_result, ncs_rpt] = mortar.compute.Gutc.normalizeQueryRefGrouped(...
    annotate_ds(query_result.cs, sig_meta, 'dim', 'row', 'keyfield', 'sig_id'),...
    rid_ref, args.ncs_group);
% set NaNs to zero
ncs_result = ds_nan_to_val(ncs_result, 0);

%% Compute Statistical Significance
Message.log(args.verbose, '# Computing statstical significance w.r.t null signatures');
is_null_sig = ds_get_meta(ncs_result, 'row', 'is_null_sig')>0;
fdr_result = mortar.compute.Gutc.computeFDRGseaDs(ncs_result, is_null_sig);
fdr_result = ds_strip_meta(fdr_result);

res = struct('args', args,...
    'query_result', query_result,...
    'ncs_result', ncs_result,...
    'ncs_rpt', ncs_rpt,...
    'fdr_result', fdr_result);

end

function sig_meta = readSigMeta(sig_meta, ncs_group, exemplar_field)
% Read signature metadata

% Fields to cast to 
num_fn = setdiff({'is_ncs_sig', 'is_null_sig', exemplar_field}, '');

if isstruct(sig_meta)
    % use as-is
elseif ischar(sig_meta)
    [~, ~, e] = fileparts(sig_meta);
    fn = readHeader(sig_meta);
    fmt_str = formatSpec(fn, num_fn);
    switch(lower(e))
        case {'.txt'}
            %sig_meta = parse_record(sig_meta_file, 'detect_numeric', false);            
            sig_meta = readtable(sig_meta, 'Delimiter', '\t', 'Format', fmt_str);
        case {'.csv'}
            %sig_meta = parse_record(sig_meta_file, 'delimiter', ',', 'detect_numeric', false);            
            sig_meta = readtable(sig_meta, 'Delimiter', ',', 'Format', fmt_str);
        otherwise
            error('Unsupported format: %s', sig_meta);
    end
    sig_meta = table2struct(sig_meta);
else
    error('sig_meta should be struct or char, got %s', class(sig_meta));
end

% Check for required signature annotation fields
req_fn = {'sig_id'};
if ~isempty(ncs_group)
    req_fn = cat(1, [req_fn(:); ncs_group(:)]);
end
assert(has_required_fields(sig_meta, req_fn, true), 'Missing metadata fields')

[tf, is_fn] = has_required_fields(sig_meta, num_fn);
if ~tf
    miss_fn = num_fn(is_fn);
    for ii=1:length(miss_fn)
        warning('field: %s missing, using all signatures', miss_fn{ii})
        sig_meta = setarrayfield(sig_meta, [], miss_fn{ii}, 1);
    end
end

end

function fn = readHeader(f)
fid = fopen(f, 'r');
line1 = fgetl(fid);
tok = textscan(line1, '%s', 'delimiter', '\t');
fn = tok{1};
fclose(fid);
end

function fmt_str = formatSpec(fn, num_fn)
nfn = length(fn);
fmt = cell(nfn, 1);
fmt(:) = {'%s'};
fmt(ismember(fn, num_fn)) = {'%u8'};
fmt_str = cat(2, fmt{:});
end