function [ds, pcl, pcl_info] = getData(args)
% Load data
    % all PCLs to score
    pcl = parse_geneset(args.pcl);

    if isempty(args.cid)
        % default to all columns in the score matrix
        cid = {};
    else
        cid = parse_grp(args.cid_id);
    end

    ds = parse_gctx(args.score, 'cid', cid);

    if args.split_by_cell
        % cast to wide form split by cell line
        ds = mortar.compute.Gutc.castDSToWide(ds, 'pert_id', 'cell_id');
        % rename duplicate cell_id to touchstone cell_id
        if ds.cdict.isKey('dup_cell_id')
       	    ds.chd{ds.cdict('dup_cell_id')} = 'ts_cell_id';
            ds.cdict = list2dict(ds.chd);
        end
    end
    
    npcl = length(pcl);
    tot_sz = sum([pcl.len], 2);
    % index to pcl
    pcl_id = zeros(tot_sz, 1);
    % index to rows of ds
    pcl_idx = zeros(tot_sz, 1);
    % pcl_size
    pcl_sz = zeros(npcl, 1);
    ctr = 0;
    if strcmpi('_rid', args.pcl_field)
        row_meta = ds.rid;
    else
        assert(ds.rdict.isKey(args.pcl_field),...
               'pcl_field not found: %s', args.pcl_field);
        row_meta = ds_get_meta(ds, 'row', args.pcl_field);
    end
    dups = duplicates(row_meta);
    assert(isempty(dups), ['Duplicate pcl_ids found in ' ...
                        'dataset']);

    lut = mortar.containers.Dict(row_meta);
    for ii=1:npcl
        isk = lut.iskey(pcl(ii).entry);        
        this_sz = nnz(isk);
        pcl_id(ctr+(1:this_sz)) = ii;
        if this_sz > 2 % consider only PCL's with more than 2 members
            pcl_idx(ctr+(1:this_sz)) = lut(pcl(ii).entry(isk));
        end
        pcl_sz(ii) = this_sz;
        ctr = ctr + this_sz;
    end
    discard = pcl_idx<1;
    pcl_id(discard) = [];
    pcl_idx(discard) = [];

    lbl = {pcl.head}';
    pcl_label = lbl(unique(pcl_id));

    rid = ds.rid(unique(pcl_idx));

    % dataset of query scores in pcl_space
    ds = ds_slice(ds, 'rid', rid);
    
    % lookup PCL members
    ds_lut = mortar.containers.Dict(ds.rid);

    % annotate if query is a member of a PCL
    if ds.cdict.isKey('pert_id')
        pid = ds_get_meta(ds, 'column', 'pert_id');
        in_pcl = ismember(pid, rid);
    else        
        in_pcl = -666*ones(size(ds.cid));
    end
    ds = ds_add_meta(ds, 'column', 'in_pcl', ...
                     num2cell(in_pcl));

    pcl_idx = ds_lut(row_meta(pcl_idx));
    pcl_info = struct('pcl_id', pcl_id,...
                         'pcl_idx', pcl_idx,... 
                         'pcl_label', {pcl_label},...
                         'pcl_sz', pcl_sz,...
                         'pcl_space', {rid});
end
