function mk_uni_lr_csv(out_path, plate_prefix, hi_csv_file, lo_csv_file)
% MK_UNI_LR_CSV Generate Luminex CSV files for UNI LR format from HiLo
% format
% mk_uni_lr_csv(out_path, plate_prefix, hi_csv_file, lo_csv_file)

%out_path = '/cmap/obelix/pod/custom/DPK/rnwork';
%plate_prefix = 'DPK.CP001_A549_24H_X1_B42_UNI5253';
%hi_csv_file = '/cmap/obelix/pod/custom/DPK/lxb/DPK.CP001_A549_24H_X1_52HI/DPK.CP001_A549_24H_X1_52HI.jcsv';
%lo_csv_file = '/cmap/obelix/pod/custom/DPK/lxb/DPK.CP001_A549_24H_X1_53LO/DPK.CP001_A549_24H_X1_53LO.jcsv';

out_left_file = fullfile(out_path, sprintf('%sL.csv', plate_prefix));
out_right_file = fullfile(out_path, sprintf('%sR.csv', plate_prefix));

hi_median = parse_csv(hi_csv_file);
lo_median = parse_csv(lo_csv_file);

hi_count = parse_csv(hi_csv_file, 'type', 'Count');
lo_count = parse_csv(lo_csv_file, 'type', 'Count');

hd_struct = hi_median.hdr;

[left_median, right_median] = uni_hilo_to_lr(hi_median, lo_median);
[left_count, right_count] = uni_hilo_to_lr(hi_count, lo_count);

mk_luminex_csv(out_left_file, hd_struct, left_median, left_count);
mk_luminex_csv(out_right_file, hd_struct, right_median, right_count);

end
