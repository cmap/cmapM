function [rankpt_ds, gset] = computeSelfMatrices(lass_path, gset, ...
                                                 gp_field, row_meta, col_meta,...
                                                 cell_id)
% COMPUTE_SELF_MATRICES Construct QxQ rankpoint matrix

% get group space

gset_space = setunion(gset);

% get pcl membership for each member
gstbl = gmt2tbl(gset);
[memb_id, pcl_memb] = group2cell({gstbl.group_id}', {gstbl.member_id}');
pcl_label = cellfun(@(x) print_dlm_line(x, 'dlm', '|'), pcl_memb, ...
                    'unif', false);

% get annotation
if isds(lass_path)
    ds_annot = lass_path;
else
    ds_annot = parse_gctx(lass_path, 'annot_only', true);
end

ds_annot = annotate_ds(ds_annot, col_meta,...
                       'dim', 'column');
gp_annot = ds_get_meta(ds_annot, 'column', gp_field);
% find overlaps with duplicates
[cidx, ig] = ismember(gp_annot, gset_space);
cid = ds_annot.cid(cidx);
% matrix is symmetric
rid = ds_annot.rid(cidx);
if isempty(cid)
    error('No PCL members found in %s', ds_annot.src);
end
% keep pcl labels for retained member
%[c, ip] = intersect_ord(memb_id, gset_space(ig(cidx)));
pcl_id_lut = mortar.containers.Dict(memb_id);
ip = pcl_id_lut(gset_space(ig(cidx)));
pcl_label = pcl_label(ip);

% extract subset of ranks
if isds(lass_path)
    rankpt_ds = parse_gctx(lass_path.src, 'cid', cid, 'rid', rid);
else
    rankpt_ds = parse_gctx(lass_path, 'cid', cid, 'rid', rid);
end

rankpt_ds = annotate_ds(rankpt_ds, row_meta,...
                       'dim', 'row');
rankpt_ds = annotate_ds(rankpt_ds, col_meta,...
                       'dim', 'column'); 
rankpt_ds = ds_add_meta(rankpt_ds, 'row', 'pcl_id', pcl_label);
rankpt_ds = ds_add_meta(rankpt_ds, 'column', 'pcl_id', pcl_label);

% insert cell_id metadata
rankpt_ds = ds_add_meta(rankpt_ds, 'column', 'cell_id', cell_id);
rankpt_ds = ds_add_meta(rankpt_ds, 'row', 'cell_id', cell_id);

end