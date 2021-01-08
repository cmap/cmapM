function ssmd_rpt = computeSSMD(ds)


pert_type = ds_get_meta(ds,'column','pert_type');
pert_iname = ds_get_meta(ds,'column','pert_iname');
det_well = ds_get_meta(ds,'column','det_well');

corner_wells = {'A01', 'A02', 'B01', 'B02',...
                'O01', 'O02', 'P01', 'P02',...
                'A23', 'A24', 'B23', 'B24',...
                'O23', 'O24', 'P23' 'P24'};

is_not_corner = ~ismember(det_well, corner_wells);
is_pos = ismember(lower(pert_iname), {'bortezomib', 'mg-132'});
is_neg = ismember(lower(pert_iname), {'dmso'});
pos_cid = ds.cid(is_pos & is_not_corner);
neg_cid = ds.cid(is_neg & is_not_corner);

pos_ds = ds_slice(ds, 'cid', pos_cid);
neg_ds = ds_slice(ds, 'cid', neg_cid);
pos_median = nanmedian(pos_ds.mat, 2);
pos_mad = mad(pos_ds.mat, 1, 2);

neg_median = nanmedian(neg_ds.mat, 2);
neg_mad = mad(neg_ds.mat, 1, 2);

ssmd = (neg_median - pos_median) ./ (1.4826 * sqrt(pos_mad.^2 + neg_mad.^2));

row_meta = gctmeta(ds, 'row');
stats = struct('ssmd', num2cell(ssmd),...
       'pos_median', num2cell(pos_median),...
       'pos_mad', num2cell(pos_mad),...
       'neg_median', num2cell(neg_median),...
       'neg_mad', num2cell(neg_mad));

ssmd_rpt = mergestruct(row_meta, stats);

end