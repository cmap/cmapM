function posconReport(zscore, varargin)
% POSCON_REPORT Run queries against positive controls on a given dataset.

% Component of Espresso, used by the Poscon modules in Roast and Brew

pnames = {'uptag',...
    'dntag',...
    'iname_map',...
    'exp_result',...
    'out',...
    'ylabelrt',...
    'rpt',...
    'metric',...
    'use_pert_desc',...
    'mkplot',...
    'connection_id'};

dflts = {'/cmap/data/vdb/queries/cred_up.gmt',...
    '/cmap/data/vdb/queries/cred_dn.gmt',...
    '/cmap/data/vdb/queries/iname_lookup.txt',...
    '/cmap/data/vdb/queries/cred_connections.txt',...
    '',...
    '',...
    '',...
    'wtcs',...
    false,...
    true,...
    ''};

args = parse_args(pnames, dflts, varargin{:});
is_weighted = strcmp('wtcs', args.metric);

%%
zs = parse_gctx(zscore);
iname = parse_tbl(args.iname_map);
cred = parse_tbl(args.exp_result);
% Validate optional connection identifier
if ~isempty(args.connection_id)
    connection_id = args.connection_id;
else
    connection_id = zs.cid;
end
assert(isequal(length(connection_id), length(zs.cid)),...
    'Dimendsions of connection_id must match the number of columns in zscore matrix, expected %d, got %d',...
    length(zs.cid), length(connection_id));
%% find inames for pert_ids
pid = ds_get_meta(zs, 'column', 'pert_id');
% brd_prefix requires a cell array of strings
if isnumeric(pid)
    pid = num2cellstr(pid);
end
% clean up brd id
brd = brd_prefix(pid);

if ~args.use_pert_desc
    brd2iname = containers.Map(iname.pert_id, iname.pert_iname);
    
    % map brd-ids to iname
    has_iname = brd2iname.isKey(brd);
    % column indices with valid iname
    cidx = find(has_iname);
    % the inames of cidx
    cid_iname = brd2iname.values(brd(has_iname));
else
    cid_iname = ds_get_meta(zs, 'column', 'pert_desc');
    cidx = (1:length(cid_iname))';
end
%% map iname to genesets in credentialed table
% 
[cred_iname_gp, cred_iname_idx] = getcls(cred.pert_iname);
cred_dict = list2dict(cred_iname_gp);
% cid_inames that are in cred
has_cred = cred_dict.isKey(cid_iname);
cred_iname_gpidx = cell2mat(cred_dict.values(cid_iname(has_cred)));
[cred_geneset_gp, cred_geneset_idx] = getcls(cred.geneset_id);

% record for each selected query
queryset = struct('geneset_id', cred.geneset_id, ...
            'iname','',...
            'directionality', '',...
            'cell_id', '',...
            'brd_id', '',...
            'cid', '',...
            'connection_id', '',...
            'num_well', '',...
            'cidx','');
cidx_lut = cidx(has_cred);
brd_lut = brd(cidx_lut);
iname_lut = cid_iname(has_cred);
%well_id = get_wellinfo(zs.cid);


for ii=1:length(cred_iname_gpidx)
    this_idx = cred_iname_idx==cred_iname_gpidx(ii);
    this_iname =  cred.pert_iname(this_idx);
    [queryset(this_idx).iname] = this_iname{:};
    this_direc =  num2cell(cred.directionality(this_idx));
    this_cell_id =  cred.cell_id(this_idx);
    [queryset(this_idx).directionality] = this_direc{:};
    [queryset(this_idx).cell_id] = this_cell_id{:};
        
    lut_idx = strcmp(this_iname{1}, iname_lut);
    % all brds matching this iname
    this_brd = brd_lut(lut_idx);   
    this_cidx = cidx_lut(lut_idx);
    this_cid = zs.cid(this_cidx);
    this_connection_id = connection_id(this_cidx);    
    
    [queryset(this_idx).brd_id] = deal(this_brd);
    [queryset(this_idx).cid] = deal(this_cid);
    [queryset(this_idx).cidx] = deal(this_cidx);
    [queryset(this_idx).connection_id] = deal(this_connection_id);
    [queryset(this_idx).num_well] = deal(length(this_connection_id));
    
end

%%
keep = ~cell2mat(cellfun(@isempty, {queryset.iname},'uniformoutput', false));
queryset=queryset(keep);

ds_cell_id = ds_get_meta(zs, 'column', 'cell_id');
is_matched_cell = ismember({queryset.cell_id}, ds_cell_id);
has_matched_cell = any(is_matched_cell);
if has_matched_cell
    dbg(1, 'Matched cell line found, using corresponding queries');
    queryset = queryset(is_matched_cell);
else
    dbg(1, 'No Matching cell line found, using all queries');
end
if ~isempty(queryset)
    %% run a cmap query query using selected genesets
    up = parse_geneset(args.uptag);
    dn = parse_geneset(args.dntag);
    [keepgs, gsidx]=intersect_ord(regexprep({up.head},'_UP|_DN',''), {queryset.geneset_id});    
    zs_rank = score2rank(zs, 'fixties', false,...
                              'direc', 'descend');
    query_res = mortar.compute.Connectivity.runCmapQuery('score', zs,...
                  'rank', zs_rank, 'uptag',up(gsidx),'dntag',dn(gsidx),'metric', args.metric);
    cs = query_res.cs;
    % compute percentile ranks per query
    cs_rank = score2rank(cs, 'as_percentile', true);
    score_file = fullfile(args.out, [print_dlm_line({'query_score', args.metric}, 'dlm', '_'), '.gct']);
    mkgct(score_file, cs);
    
    rank_file = fullfile(args.out, [print_dlm_line({'query_rank', args.metric}, 'dlm', '_'), '.gct']);
    mkgct(rank_file, cs_rank);
    
    %% well connectivity rpt, one row per well/geneset combination
    
    assert(isequal({queryset.geneset_id}', cs.cid), 'geneset order mismatch');
    total_well = size(cs.mat, 1);
    nrow = sum([queryset.num_well]);
    plate_id = {args.ylabelrt};
    well_rpt = struct('plate_id', plate_id(ones(nrow,1)),...
        'cid', '',...
        'connection_id', '',...
        'pert_id', '',...
        'pert_iname', '',...
        'pert_type', '',...
        'geneset_id', '',...
        'query_cell_id', '',...
        'cmap_score', '',...
        'cmap_rank', '',...
        'max_rank', total_well,...
        'up_es', '',...
        'dn_es', '',...
        'is_wtcs', is_weighted);
    
    offset = [ 0 cumsum([queryset.num_well])];
    pert_type = ds_get_meta(cs,'row','pert_type');
    for ii=1:length(queryset)
        for jj=1:queryset(ii).num_well
            ir = offset(ii) + jj;
            well_rpt(ir).cid = queryset(ii).cid{jj};
            well_rpt(ir).connection_id = queryset(ii).connection_id{jj};
            well_rpt(ir).pert_id = queryset(ii).brd_id{jj};
            well_rpt(ir).pert_iname = queryset(ii).iname;
            well_rpt(ir).geneset_id = queryset(ii).geneset_id;
            well_rpt(ir).query_cell_id = queryset(ii).cell_id;
            well_rpt(ir).directionality = queryset(ii).directionality;
            
            % metrics
            well_rpt(ir).cmap_score = cs.mat(queryset(ii).cidx(jj), ii);
            well_rpt(ir).cmap_rank = cs_rank.mat(queryset(ii).cidx(jj), ii);
            well_rpt(ir).up_es = query_res.cs_up.mat(queryset(ii).cidx(jj), ii);
            well_rpt(ir).dn_es = query_res.cs_dn.mat(queryset(ii).cidx(jj), ii);
            well_rpt(ir).pert_type = pert_type{queryset(ii).cidx(jj)};
        end
    end
    
    % connection report
    % Add is_best_query field
    well_rpt = pick_top_query_results(well_rpt);
    mktbl(fullfile(args.out, 'connection_summary.txt'), well_rpt);
    %% barview plot
    if args.mkplot
        if ~has_matched_cell
            top_well_rpt = well_rpt([well_rpt.is_best_query]'>0);
            top_cid = unique({top_well_rpt.geneset_id}', 'stable');
            top_cs = ds_slice(cs, 'cid', top_cid);    
            [~, ~, ib] = intersect(top_cid, {queryset.geneset_id}', 'stable');
            top_queryset = queryset(ib);
        else
            top_well_rpt = well_rpt;
            top_cs = cs;
            top_queryset = queryset;
        end
        gpv = get_groupvar(top_queryset, [], {'iname', 'cell_id'});        
        [sort_gpv, sort_idx] = sort(gpv);
        ticks = {top_queryset.cidx};
        title_text = sprintf('Poscon Connectivity: %d queries, %d unique wells',...
            length(top_queryset), length(unique({top_well_rpt.connection_id})));
        img_name = print_dlm_line({'poscon_query', args.metric}, 'dlm', '_');
        if ~isempty(args.connection_id)
            rid = connection_id;
        else
            rid = '';
        end
        plot_barviewh(top_cs.mat(:, sort_idx), 'mark_index', ticks(sort_idx),...
            'columnlabel', texify(sort_gpv), 'rid', rid, 'title', title_text,...
            'showfig', false, 'name', img_name, 'ylabelrt', args.ylabelrt)
        savefigures('out', args.out, 'mkdir', false, 'closefig', true, 'overwrite', true);
    end
else
    dbg(1, 'No poscons found, skipping');
end
end

function well_rpt = pick_top_query_results(well_rpt)
[gpv, gpn, gpi] = get_groupvar(well_rpt, [], {'geneset_id', 'pert_iname'}, 'dlm', '#');
% query groups
[q_gpv, q_gpn, q_gpi] = get_groupvar(well_rpt, [], {'geneset_id'}, 'dlm', '#');
% name groups
[n_gpv, n_gpn, n_gpi] = get_groupvar(well_rpt, [], {'pert_iname'}, 'dlm', '#');

num_iname_group = length(n_gpn);
is_best_query = false(length(well_rpt), 1);
for ii=1:num_iname_group
    this_iname = find(n_gpi == ii);
    this_query = {well_rpt(this_iname).geneset_id}';
    this_cs = [well_rpt(this_iname).cmap_score]';
    [qid, med_cs] = grpstats(this_cs, this_query, {'gname', 'median'});
    [max_cs, max_idx] = max(med_cs);
    this_best = ismember(this_query, qid{max_idx});
    is_best_query(this_iname(this_best)) = true;
end
well_rpt = setarrayfield(well_rpt, [], 'is_best_query', is_best_query);

end