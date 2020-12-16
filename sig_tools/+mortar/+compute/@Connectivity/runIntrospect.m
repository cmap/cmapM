function res = runIntrospect(varargin)
% runIntrospect Compute internal connectivities between signatures
% type runIntrospect('-h') for details

[args, help_flag] = getArgs(varargin{:});
import mortar.util.Message

if ~help_flag
    import mortar.compute.Connectivity
    import mortar.compute.Gutc
    
    Message.log(args.verbose, '# Begin Introspect');
    % load data, returns query object
    qo = loadData(args);
    nr = length(qo.rid);
    nq = length(qo.query_id);
    % run self query
    % run bkg query
    % merge results
    % NormalizeOOB the results
    % extract percentiles of NxN matrices
    t0 = tic;
    Message.log(args.verbose, '# Running self-queries');
    if isempty(qo.sig_connectivity)
        self_res = mortar.compute.Connectivity.runCmapQuery(...
            '--up', qo.up,...
            '--dn', qo.dn,...
            '--score', qo.sig_score,...
            '--rank', qo.sig_rank,...
            '--metric', args.metric,...
            '--es_tail', args.es_tail);
        meta_self = gctmeta(qo.sig_rank);
        meta_self = mvfield(meta_self, 'cid', 'rid');
    else
        self_res = struct('cs', qo.sig_connectivity);
        meta_self = gctmeta(qo.sig_connectivity);
        meta_self = mvfield(meta_self, 'cid', 'rid');
    end
    
    if isempty(qo.bkg_connectivity)
        Message.log(args.verbose, '# No Background supplied, using self-background');
        full_res = ds_strip_meta(self_res.cs);
        meta_bkg = meta_self;
        meta = meta_self;
    else
        Message.log(args.verbose, '# Using pre-computed background');
        meta_bkg = gctmeta(qo.bkg_connectivity, 'row');
        % exclude ids that intersect with test dataset
        [bkg_rid, ibkg] = setdiff(qo.bkg_connectivity.rid, self_res.cs.rid);
        if ~isempty(bkg_rid)
            full_res = merge_two(ds_strip_meta(self_res.cs),...
                ds_slice(ds_strip_meta(qo.bkg_connectivity), 'rid',...
                bkg_rid));
            meta = [keepfield(meta_self, {'rid','pert_type','cell_id'});...
                keepfield(meta_bkg(ibkg), {'rid','pert_type','cell_id'})];
        else
            % No unique row-ids default to self bkg
            Message.log(args.verbose, '# Self and Background Row Ids are identical, using self-background');            
            full_res = ds_strip_meta(self_res.cs);
            meta_bkg = meta_self;
            meta = meta_self;
        end
    end
    
    full_res = annotate_ds (full_res, meta, 'dim', 'row', 'keyfield', 'rid');
    
    Message.log(args.verbose, '# Normalizing scores relative to background');
    [ncs, rpt, pos_mean, neg_mean] = ...
        mortar.compute.Gutc.normalizeQueryRef(full_res, {meta_bkg.rid});
    
    Message.log(args.verbose, '# Computing score percentile transform');
    % Rank each column relative to bkg signatures
    ns2ps = mortar.compute.Gutc.scoreToPercentileTransform(...
        ds_slice(ncs, 'rid', {meta_bkg.rid}),...
        'column', -4, 4, 10000);
    % arguments
    res.args = args;
    
    % sets that were used
    res.up = qo.up;
    res.dn = qo.dn;
    
    % Raw Connectivity scores (NxN)
    res.cs = self_res.cs;
    res.cs = annotate_ds(res.cs, meta_self, 'dim', 'row');
    res.cs = annotate_ds(res.cs, meta_self, 'dim', 'column');
    
    % Normalized scores (NxN)
    res.ncs = ds_slice(ncs, 'rid', ncs.cid);
    res.ncs = annotate_ds(res.ncs, meta_self, 'dim', 'row');
    res.ncs = annotate_ds(res.ncs, meta_self, 'dim', 'column');
    
    % Percentile scores
    Message.log(args.verbose, '# Computing percentile scores');
    % PS for each row (self + bkg)
    full_ps = mortar.compute.Gutc.scoreToPercentile(ncs, ns2ps, 'row');
    
    % introspect percentile scores (NxN)
    res.ps = ds_slice(full_ps, 'rid', ncs.cid);
    res.ps = annotate_ds(res.ps, meta_self, 'dim', 'row');
    res.ps = annotate_ds(res.ps, meta_self, 'dim', 'column');
    
    % background percentile scores (RxN)
    res.ps_bkg = ds_slice(full_ps, 'rid', {meta_bkg.rid});
    res.ps_bkg = annotate_ds(res.ps_bkg, meta_bkg, 'dim', 'row');
    res.ps_bkg = annotate_ds(res.ps_bkg, meta_self, 'dim', 'column');
    
    if args.symmetricize_result
        res.cs = ds_make_symmetric(res.cs, 'mean', nan);
        res.ncs = ds_make_symmetric(res.ncs, 'mean', nan);
        res.ps = ds_make_symmetric(res.ps, 'mean', nan);
    end
    
    Message.log(args.verbose, '# END Introspect [%2.1f s].', toc(t0));
end
end

function [up, dn] = loadGeneset(score, gset_size, es_tail)
% Load data needed for running a query
[up, dn] = get_genesets(score, gset_size, 'descend');
switch es_tail
    case 'both'
    case 'up'
        dn = mkgmtstruct({},{},{});
    case 'down'
        up = mkgmtstruct({},{},{});
    otherwise
        error('Invalid es_tail specified : %s', es_tail);
end
end


function res = loadData(args)
%%% Parse args and load data
import mortar.util.Message

% outputs
res_fields = {'up', 'dn', 'rid',...
    'cid', 'max_rank', 'query_id',...
    'is_weighted',...
    'block_size', 'sig_score', 'sig_rank',...
    'es_tail', 'sig_connectivity', 'bkg_connectivity',...
    'use_self_as_bkg'};

res = cell2struct(cell(size(res_fields)), res_fields,2);

% signature matrix or pre-computed connectivity
is_sig_connectivity = ~isempty(args.sig_connectivity);
if is_sig_connectivity
    Message.log(args.verbose, '# Pre-computed connectivity matrix supplied, loading...');
    sig_meta = parse_gctx(args.sig_connectivity, 'annot_only', true);
    nrow = length(sig_meta.rid);
    ncol = length(sig_meta.cid);
    assert(isequal(nrow, ncol),...
        'Expected square sig_connectivity matrix, got %d x %d', nrow, ncol);
    res.sig_connectivity = parse_gctx(args.sig_connectivity);
else
    Message.log(args.verbose, ['# Signature matrix supplied.' ...
        'Loading %s feature space...'], args.row_space);
    if ~isempty(args.rid)
        % custom space
        args.row_space = 'custom';
        rid =  parse_grp(args.rid);
    elseif ~strcmpi(args.row_space, 'all')
        % pre-defined row_space
        is_valid_row_space = mortar.common.Spaces.probe_space.isKey(args.row_space);
        assert(is_valid_row_space, 'Invalid row space %s', args.row_space);
        rid = mortar.common.Spaces.probe(args.row_space).asCell;
    else
        % default to all
        rid = '';
    end
    res.sig_score = parse_gctx(args.sig_score, 'rid', rid);
    if ~isempty(args.sig_rank)
        Message.log(args.verbose, '# Rank matrix supplied, loading...');
        res.sig_rank = parse_gctx(args.sig_rank);
    else
        Message.log(args.verbose, '# Rank matrix not supplied, computing...');
        res.sig_rank = score2rank(res.sig_score);
    end
    assert(all(ismember(res.sig_score.rid, res.sig_rank.rid)), ...
        'Feature space mismatch between score and rank matrices')
    
    % Create genesets
    Message.log(args.verbose, '# Generating %d query sets...', numel(res.sig_score.cid));
    [res.up, res.dn] = loadGeneset(res.sig_score, args.gset_size, args.es_tail);
    % validate and filter spurious features
    rid_dict = mortar.containers.Dict(res.sig_rank.rid);
    [res.up, res.dn] = mortar.compute.Connectivity.checkGenesets(res.up,...
        res.dn,...
        rid_dict,...
        args.es_tail);
    % full feature space of queries
    res.rid = setunion([res.up; res.dn]);
    % maximum rank
    res.max_rank = length(res.sig_rank.rid);
    % tail to use for query
    res.es_tail = args.es_tail;
end

% column annotations
if ~isempty(args.sig_col_meta)
    sig_col_meta = parse_record(args.sig_col_meta);
    if is_sig_connectivity
        res.sig_connectivity = annotate_ds(res.sig_connectivity, sig_col_meta, 'dim', 'column');
    else
        res.sig_score = annotate_ds(res.sig_score, sig_col_meta, 'dim', 'column');
        res.sig_rank = annotate_ds(res.sig_rank, sig_col_meta, 'dim', 'column');
    end
end
% check if annotations are complete
req_col_fn = {'cell_id', 'pert_type'};
if is_sig_connectivity
    res.sig_connectivity = ds_add_dummy_meta(res.sig_connectivity, 'column', req_col_fn);        
    query_cid = res.sig_connectivity.cid;
else
    res.sig_score = ds_add_dummy_meta(res.sig_score, 'column', req_col_fn); 
    res.sig_rank = ds_add_dummy_meta(res.sig_rank, 'column', req_col_fn); 
    query_cid = res.sig_score.cid;
end

if ~isempty(args.bkg_connectivity)
    Message.log(args.verbose, '# Pre-computed background supplied');
    bkg_annot = parse_gctx(args.bkg_connectivity, 'annot_only', true);
    % check if queries match
    cid = intersect(bkg_annot.cid, query_cid, 'stable');
    if ~(isequal(length(cid), length(query_cid)))
        miss = setdiff(query_cid, bkg_annot.cid);
        disp(miss)
        error('Missing %d queries in background result', numel(miss));
    end
    
    if ~isempty(args.bkg_row_meta)
        Message.log(args.verbose, '# Reading background row metadata');
        bkg_row_meta = parse_record(args.bkg_row_meta);
        fn = fieldnames(bkg_row_meta);
        key_fn = fn(strcmp(fn, 'id'));
        if isempty(key_fn)
            key_fn = fn{1};
        end
        Message.log(args.verbose, '# Using keyfield %s for joining...', key_fn);
        key_field = {bkg_row_meta.(key_fn)}';
        rid = intersect(bkg_annot.rid, key_field, 'stable');
        assert(~isempty(rid), ['No annotations found for background ' ...
            'results']);
        if ~isequal(length(bkg_annot.rid), length(rid))
            miss = setdiff(bkg_annot.rid, rid);
            warning(['Missing annotations for %d/%d connections in background result, ' ...
                'ignoring them...'], numel(miss), ...
                numel(bkg_annot.rid));
        end
        % check if row annotations are present
        assert(all(isfield(bkg_row_meta, {'pert_type', 'cell_id'})),...
            'Missing row annotations in background result: cell_id, pert_type' )
        re_annotate = true;
    else
        rid = '';
        % check if row annotations are present
        assert(all(ismember({'pert_type', 'cell_id'}, bkg_annot.rhd)),...
            'Missing row annotations in background result: cell_id, pert_type' )
        re_annotate = false;
    end
    res.bkg_connectivity = parse_gctx(args.bkg_connectivity, 'cid', ...
        cid);
    res.bkg_connectivity = ds_slice(res.bkg_connectivity, 'rid', ...
        rid);
    Message.log(args.verbose, '# Using %d signatures as background', numel(rid));
    if re_annotate
        Message.log(args.verbose, '# Annotating background matrix');
        res.bkg_connectivity = annotate_ds(res.bkg_connectivity, ...
            bkg_row_meta, 'dim', 'row');
    end
    res.use_self_as_bkg = false;
else
    Message.log(args.verbose, '# No background supplied, using provided signatures as background.');
    res.use_self_as_bkg = true;
end

end

function [args, help_flag] = getArgs(varargin)
%%% Parse arguments
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', 'Run a CMap query', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    %     % work dir
    %     if args.mkdir
    %         wkdir = mktoolfolder(args.out, mfilename, 'prefix', args.rpt);
    %     else
    %         if isempty(args.out)
    %             args.out = pwd;
    %         end
    %         wkdir = args.out;
    %         if ~isdirexist(wkdir)
    %             mkdir(wkdir);
    %         end
    %     end
    
    %     args_save = args;
    %     % handle remote URLs
    %     args = get_config_url(args, wkdir, true);
    %
    %     % save config with remote URLS if applicable
    %     WriteYaml(fullfile(wkdir, 'config.yaml'), args_save);
    %     args.out = wkdir;
end
end
