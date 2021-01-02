function mat = annotateInterCellMatrix(mat, annot)
    keep_field = {'group_id', 'pert_id','pert_iname','cell_id','pert_type', 'group_size'};
    annot = rmfield(annot, setdiff(fieldnames(annot), keep_field));
    mat = annotate_ds(mat, annot, 'dim', 'row', 'keyfield', 'group_id');
end