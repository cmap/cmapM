function res =  runCmapQueryContest(varargin)
% runCmapQueryContest run Cmap queries on a user specified dataset 
% optimized for CMAP2 Contest
% See runCMapQueryContest('--help') for details

[args, help_flag] = getArgs(varargin{:});

if ~help_flag
    
    % load data, returns query object
    qo = loadData(args);
    nr = length(qo.cid);
    nq = length(qo.query_id);
    % run query
    t0 = tic;
    dbg(1, '## Query Mode: %s', qo.query_mode);
    switch qo.query_mode
        case 'full'
            % run in one shot
            [score] = ...
                mortar.compute.Connectivity.cmapScoreCore(qo.upind, qo.dnind,...
                qo.rank, qo.max_rank,...
                qo.is_weighted, qo.score,...
                qo.es_tail);
        case 'iterative'
            nblock = ceil(nr / qo.block_size);
            iblock = 1;
            dbg(1, '## Reading %d columns in %d blocks each of size %d', nr, nblock, qo.block_size);
            % iterate and accumulate results
            score = zeros(nr, nq, 3);
            %leadf = zeros(nr, nq, 2); 
            [ds_score, cur_score, ds_rank, cur_rank, idx_start, idx_stop] = ...
                getMatrixColumns(qo, [], []);
            while ~isempty(ds_score) || ~isempty(ds_rank)
                dbg(1, '## Block %d/%d %d-%d',...
                    iblock, nblock, cur_score.idx_start, cur_score.idx_stop);
                % Compute CMAP enrichment statistic
                [score(idx_start:idx_stop, :, :)] = ...
                    mortar.compute.Connectivity.cmapScoreCore(qo.upind, qo.dnind,...
                    ds_rank, qo.max_rank,...
                    qo.is_weighted, ds_score,...
                    qo.es_tail);
                [ds_score, cur_score, ds_rank, cur_rank, idx_start, idx_stop] = ...
                    getMatrixColumns(qo, cur_score, cur_rank);
                iblock = iblock + 1;
            end
        otherwise
            error('Invalid query_mode: %s', qo.query_mode);
    end
    tend = toc(t0);
    dbg(1, '## Query Completed: %2.4f', tend);
    
%     % sets that were used
%     res.uptag = qo.uptag;
%     res.dntag = qo.dntag;
    
    % combined score
    res.cs = mkgctstruct(score(:,:,3), 'rid', qo.cid,...
        'cid', qo.query_id, 'chd', {'desc'}, 'cdesc', qo.query_desc);
%     % up score
%     res.cs_up = mkgctstruct(score(:,:,1), 'rid', qo.cid,...
%         'cid', qo.query_id);
%     
%     % down score
%     res.cs_dn = mkgctstruct(score(:,:,2), 'rid', qo.cid,...
%         'cid', qo.query_id);
%     
%     %leading fraction up
%     res.leadf_up = mkgctstruct(leadf(:,:,1), 'rid', qo.cid,...
%         'cid', qo.query_id);
%     
%     % leading fraction down
%     res.leadf_dn = mkgctstruct(leadf(:,:,2), 'rid', qo.cid,...
%         'cid', qo.query_id);
end
end

function [uptag, dntag] = loadGeneset(uptag, dntag, es_tail)
% Load data needed for running a query
switch es_tail
    case 'both'
        if mortar.util.File.isfile(uptag, 'file') || isstruct(uptag)
            uptag = parse_geneset(uptag);
        elseif ischar(uptag)
            error('Up geneset not found');
        end
        if mortar.util.File.isfile(dntag, 'file') || isstruct(dntag)
            dntag = parse_geneset(dntag);
        elseif ischar(dntag)
            error('Down geneset not found');
        end
    case 'up'
        if mortar.util.File.isfile(uptag, 'file') || isstruct(uptag)
            uptag = parse_geneset(uptag);
        elseif ischar(uptag)
            error('Up geneset not found');
        end
        dntag = [];
    case 'down'
        if mortar.util.File.isfile(dntag, 'file') || isstruct(dntag)
            dntag = parse_geneset(dntag);
        elseif ischar(dntag)
            error('Down geneset not found');
        end
        uptag = [];
    otherwise
        error('Invalid es_tail specified : %s', es_tail);
end
end


function res = loadData(args)
%%% Parse args and load query data

% outputs
res_fields = {'uptag', 'dntag', 'rid',...
    'cid', 'max_rank', 'query_id',...
    'upind', 'dnind', 'is_weighted',...
    'block_size', 'score', 'rank',...
    'es_tail', 'query_desc', 'rank_score'};

res = cell2struct(cell(size(res_fields)), res_fields,2);

if ~isempty(args.rank_score)
    % process Rank-Score format if provided
    res.rank_score = args.rank_score;
    annot = parse_gctx(args.rank_score, 'annot_only', true);
    rid_dict = mortar.containers.Dict(annot.rid);
    res.max_rank = length(annot.rid);
    if ~isempty(args.cid)
        cid = parse_grp(args.cid);
        res.cid = intersect(annot.cid, cid);
        is_custom_cid = true;
    else
        res.cid = annot.cid;
        is_custom_cid = false;
    end
    
    is_gctx = true;
else
    res.score = args.score;
    res.rank = args.rank;
    
    if isds(res.rank)
        rid_dict = mortar.containers.Dict(res.rank.rid);
        res.max_rank = length(res.rank.rid);
        if ~isempty(args.cid)
            cid = parse_grp(args.cid);
            res.cid = intersect(res.rank.cid, cid);
            is_custom_cid = true;
        else
            res.cid = res.rank.cid;
            is_custom_cid = false;
        end
        
        is_gctx = false;
    elseif mortar.util.File.isfile(res.rank, 'file')
        annot = parse_gctx(args.rank, 'annot_only', true);
        rid_dict = mortar.containers.Dict(annot.rid);
        res.max_rank = length(annot.rid);
        if ~isempty(args.cid)
            cid = parse_grp(args.cid);
            res.cid = intersect(annot.cid, cid);
            is_custom_cid = true;
        else
            res.cid = annot.cid;
            is_custom_cid = false;
        end
        [~,~,e] = fileparts(res.rank);
        is_gctx = strcmpi(e, '.gctx');
        
    elseif ischar(args.rank)
        error('Rank file not found');
    end
    
end

res.es_tail = args.es_tail;

% read genesets
[res.uptag, res.dntag] = loadGeneset(args.uptag, args.dntag, args.es_tail);

% validate and filter spurious features
[res.uptag, res.dntag] = mortar.compute.Connectivity.checkGenesets(res.uptag, res.dntag,...
    rid_dict, args.es_tail);

% full feature space
res.rid = setunion([res.uptag; res.dntag]);

% lookup row indices for each geneset
[res.upind, res.dnind, res.query_id, res.query_desc] = computeGeneIndices(res.uptag, res.dntag, args.es_tail,...
    mortar.containers.Dict(res.rid));

% Determine number of columns to load at a time.
res.is_weighted = isequal(args.metric, 'wtcs');
%nds = 1 + res.is_weighted;
%nr = length(res.rid);
nc = length(res.cid);
%res.block_size = min(nc, ceil(args.max_el / (nr * (nds)^2)));
res.block_size = min(nc, args.max_col);

% determine query mode
if is_gctx && (nc > res.block_size)
    res.query_mode = 'iterative';
else
    res.query_mode = 'full';
    if ~isempty(args.rank_score)
        if is_custom_cid
            [res.score, res.rank] = mortar.compute.Connectivity.defuseRankScore(args.rank_score);
        else
            ds_rank_score = parse_gctx(res.rank_score, 'rid', res.rid, 'cid', res.cid, 'verbose', false);
            [res.score, res.rank] = mortar.compute.Connectivity.defuseRankScore(ds_rank_score);
        end
    else
        if is_custom_cid
            res.score = parse_gctx(res.score, 'rid', res.rid, 'cid', res.cid, 'verbose', false);
            res.rank = parse_gctx(res.rank, 'rid', res.rid, 'cid', res.cid, 'verbose', false);
        else
            res.score = parse_gctx(res.score, 'rid', res.rid);
            res.rank = parse_gctx(res.rank, 'rid', res.rid);
        end
    end
end

end

function [upind, dnind, query_id, query_desc] = computeGeneIndices(uptag, dntag, es_tail, rid_dict)
% Get row indices into the rank (score) matrix for each geneset

switch(lower(es_tail))
    case 'both'
        upind = tag2idx({uptag.entry}, rid_dict);
        dnind = tag2idx({dntag.entry}, rid_dict);
        query_id = regexprep(upper({uptag.head}'), '_UP$', '');
        query_desc = {uptag.desc}';
    case 'up'
        upind = tag2idx({uptag.entry}, rid_dict);
        dnind = {};
        query_id = regexprep(upper({uptag.head}'), '_UP$', '');
        query_desc = {uptag.desc}';
    case 'down'
        upind = {};
        dnind = tag2idx({dntag.entry}, rid_dict);
        query_id = regexprep(upper({dntag.head}'), '_DN$', '');
        query_desc = {dntag.desc}';
end
end

function [ds_score, cur_score, ds_rank, cur_rank, idx_start, idx_stop] = ...
            getMatrixColumns(qo, cur_score, cur_rank)
%%% Iterate over columns of the score and rank matrices
idx_start = 0;
idx_stop = 0;
ds_score = [];
ds_rank = [];
if ~isempty(qo.rank_score)
    % Rank score iteration
    % Note we use the score cursor
    [ds_rore, cur_score] = ds_iter(qo.rank_score, qo.block_size, cur_score,...
        'rid', qo.rid,...
        'cid', qo.cid);

    if ~isempty(cur_score)
        [ds_score, ds_rank] = mortar.compute.Connectivity.defuseRankScore(ds_rore);
        idx_start = cur_score.idx_start;
        idx_stop = cur_score.idx_stop;        
    end
    cur_rank = [];
else
    if ~isempty(qo.score)
        [ds_score, cur_score] = ds_iter(qo.score, qo.block_size, cur_score,...
            'rid', qo.rid,...
            'cid', qo.cid);
        if ~isempty(cur_score)
            idx_start = cur_score.idx_start;
            idx_stop = cur_score.idx_stop;
        end
    end
    
    if ~isempty(qo.rank)
        [ds_rank, cur_rank] = ds_iter(qo.rank, qo.block_size, cur_rank,...
            'rid', qo.rid,...
            'cid', qo.cid);
        if ~isempty(cur_rank)
            idx_start = cur_rank.idx_start;
            idx_stop = cur_rank.idx_stop;
        end
    end
end
end

function idx = tag2idx(tags, dict)
% Lookup indices for tags
% note this seems much faster than a cellfun lookup at least for nt>1000
nt = length(tags);
idx = cell(nt, 1);
for ii=1:nt
    idx{ii} = cell2mat(dict.values(tags{ii}));
end
end

function [args, help_flag] = getArgs(varargin)
%%% Parse arguments
ConfigFile = mortar.util.File.getArgPath(mfilename, mfilename('class'));
opt = struct('prog', mfilename, 'desc', '', 'undef_action', 'ignore');
[args, help_flag ] = mortar.common.ArgParse.getArgs(ConfigFile, opt, varargin{:});

if ~help_flag
    % sanity checks
end
end
