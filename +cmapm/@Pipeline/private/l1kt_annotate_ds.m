%% functionname: function description
function annotds = l1kt_annotate_ds(ds, annot, dim)
annotds = ds;
annot_names = fieldnames(annot);
[n_annot_names, ~] = size(annot_names);
for x=1:n_annot_names
    field = annot_names{x};
    disp(field)
    annotds = ds_add_meta(annotds, dim, field, {annot.(field)}');
end

end