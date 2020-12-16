function rpt = getXiconTable(ds_row_meta, xicon_tbl, pcl_set, moa_tbl, match_field)
%% getXiconTable Generate table of expected connections (aka connect-icons)
% rpt = getXiconTable(ds_row_meta, xicon_tbl, pcl_set, moa_tbl)

% Types of connections
% self: Self
% gene_kd : Gene KD
% gene_oe : Gene OE
% gene_cpr : Gene Crispr knockout
% moa : Perturbagens sharing the samme mechanism of action
% pcl : PCLs
% pcl_member: PCL members

%ds_match_field = 'pert_iname';
%xicon_match_field = 'pert_iname';

req_fn = {'pert_id', 'moa', 'target_name', 'pcl_ids', match_field};
[has_req_fn, is_req_fn] = has_required_fields(xicon_tbl, req_fn, true);
assert(has_req_fn, 'Required fields not found in xicon_tbl : %s',...
       print_dlm_line(req_fn(~is_req_fn), 'dlm', ','));

xicon_type = {'self'; 'pcl'; 'moa';...
              'gene_kd'; 'gene_xpr'; 'gene_oe';...
              'pcl_member'; 'cp_target'};

nxicon = length({xicon_tbl.pert_id}');

rid = {ds_row_meta.rid}';
pert_id = {ds_row_meta.pert_id}';
pert_iname = {ds_row_meta.pert_iname}';
pert_type = {ds_row_meta.pert_type}';
is_kd = strcmp('trt_sh.cgs', pert_type);
is_oe = strcmp('trt_oe', pert_type);
is_xpr = strcmp('trt_xpr', pert_type);
xicon_sets = [];

ds_match_id = {ds_row_meta.(match_field)}';

pcl_member_tbl = gmt2tbl(pcl_set);

% create moa lookup table
moa_lut = genLookupTable(ds_row_meta, match_field, 'moa', '|');
target_lut = genLookupTable(ds_row_meta, match_field, 'target_name', '|');

for ii=1:nxicon
% self connections
is_self_match = ismember(lower(ds_match_id), lower({xicon_tbl(ii).(match_field)}'));
self_rid = rid(is_self_match);

if ~isempty(xicon_tbl(ii).moa) && ~strcmp('-666', xicon_tbl(ii).moa) && ~isnumeric(xicon_tbl(ii).moa)
    this_moa = tokenize(xicon_tbl(ii).moa, '|', true);
    is_moa_tbl_match = ismember(lower({moa_lut.moa}'), lower(this_moa));
    is_moa_match = ~is_self_match & ismember(ds_match_id, {moa_lut(is_moa_tbl_match).(match_field)}');
    moa_rid = rid(is_moa_match);
else
    moa_rid = {};
end

if ~isempty(xicon_tbl(ii).target_name) && ~strcmp('-666', xicon_tbl(ii).target_name) && ~isnumeric(xicon_tbl(ii).target_name)
    this_target = tokenize(xicon_tbl(ii).target_name, '|', true);
    is_gene_match = ismember(lower(pert_iname), lower(this_target));
    is_gene_kd_match = ~is_self_match & is_gene_match & is_kd;
    is_gene_oe_match = ~is_self_match & is_gene_match & is_oe;    
    is_gene_xpr_match = ~is_self_match & is_gene_match & is_xpr;    
    
    gene_kd_rid = rid(is_gene_kd_match);
    gene_oe_rid = rid(is_gene_oe_match);
    gene_xpr_rid = rid(is_gene_xpr_match);
    
    is_target_tbl_match = ismember(lower({target_lut.target_name}'), lower(this_target));
    is_target_match = ~is_self_match & ismember(lower(ds_match_id), lower({target_lut(is_target_tbl_match).(match_field)}'));
    cp_target_rid = rid(is_target_match);
    
else
    gene_kd_rid  = {};
    gene_oe_rid = {};
    gene_xpr_rid = {};
    cp_target_rid = {};
end

if ~isempty(xicon_tbl(ii).pcl_ids) && ~isnumeric(xicon_tbl(ii).pcl_ids) && ~strcmp('-666', xicon_tbl(ii).pcl_ids)
    this_pcl_id = tokenize(xicon_tbl(ii).pcl_ids, '|', true);    
    is_pcl_match = ~is_self_match & ismember(ds_match_id, this_pcl_id);
    % members of PCL
    is_pcl_member_match = ismember({pcl_member_tbl.group_id}', this_pcl_id);
    this_pcl_member_id = {pcl_member_tbl(is_pcl_member_match).member_id}';
    is_pcl_pert_match = ~is_self_match & ismember(ds_match_id, this_pcl_member_id);    
    pcl_rid = rid(is_pcl_match);
    pcl_member_rid = rid(is_pcl_pert_match);
else
    pcl_rid = {};
    pcl_member_rid = {};
end

this_set = getSets(xicon_tbl(ii).(match_field), xicon_type,...
                   {self_rid, pcl_rid, moa_rid,...
                   gene_kd_rid, gene_xpr_rid, gene_oe_rid,...
                   pcl_member_rid, cp_target_rid});
xicon_sets = [this_set; xicon_sets];
end

rpt = gmt2tbl(xicon_sets);
tok = get_tokens({rpt.desc}', [1,2], 'dlm', '|');
rpt = mvfield(rpt, {'desc'}, {'xicon_type'});
rpt = setarrayfield(rpt, [], {'xicon_type', 'xicon_match_value'}, tok(:, 1),  tok(:,2));
rpt = setarrayfield(rpt, [], {'xicon_match_field'}, match_field);
rpt = join_table(rpt, ds_row_meta, 'member_id', 'rid');

end

function set = getSets(xicon_match_id, xicon_type, entries)
hd = upper(strcat(xicon_match_id, '_', xicon_type));
desc = strcat(xicon_type, '|', xicon_match_id);
set = mkgmtstruct(entries, hd, desc);
set = set([set.len]'>0);
end


function lut = genLookupTable(tbl, id_field, lookup_field, unwrap_dlm)

lut = unwrap_table(keepfield(tbl, {id_field, lookup_field}), lookup_field, unwrap_dlm);

end