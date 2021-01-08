function [left_ds, right_ds] = uni_hilo_to_lr(hi_ds, low_ds)
% UNI_HILO_TO_LR Convert L1000 UNI data Detected in HiLo format to
% Left/Right format
%   [left_ds, right_ds] = uni_hilo_to_lr(hi_ds, low_ds)
%   Hi:  |Hi-L|Hi-R|, Low: |Lo-L|Lo-R|
%   Left: |Hi-L|Lo-L|, Right: |Hi-R|Lo-R|

% handle missing data
cmn_cid = intersect(low_ds.cid, hi_ds.cid);
%[cmn_rid,ilo_rid,ihi_rid] = intersect(low_ds.rid, hi_ds.rid);
platemap_file = fullfile(mortarpath,'resources','384_plate.txt');
platemap = parse_record(platemap_file);
wn = get_wellinfo(cmn_cid);
[~, missing_idx] = setdiff({platemap.wellzero}', wn);
missing_wn = {platemap(missing_idx).well}';
missing_colord = [platemap(missing_idx).colmajor_order]';
missing_colord_cell = num2cell(missing_colord);
v = [missing_colord_cell, missing_wn]';
tok = tokenize(sprintf('%d(1,%s)#', v{:}),'#');
missing_well = tok(1:end-1);
all_wn = union(cmn_cid, missing_well);
[wn2, word2] = get_wellinfo(all_wn);
[~, sort_idx] = sort(word2);
all_wn = all_wn(sort_idx);
% insert missing wells temporarily
hi_ds = ds_pad(hi_ds, [], all_wn, nan);
low_ds = ds_pad(low_ds, [], all_wn, nan);

% ensure same ordering for rows and columns
low_ds = ds_slice(low_ds, 'rid', hi_ds.rid,...
                         'cid', hi_ds.cid);

[wn, word] = get_wellinfo(hi_ds.cid);

is_left = word<=192;
is_right = ~is_left;

left_ds = hi_ds;
left_ds.mat(:, is_right) = low_ds.mat(:, is_left);

right_ds = low_ds;
right_ds.mat(:, is_left) = hi_ds.mat(:, is_right);

% exclude missing wells
left_ds = ds_delete_missing(left_ds);
right_ds = ds_delete_missing(right_ds);

end