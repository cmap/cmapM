function tbl = tbl_concat(tbl_list)
% TBL_CONCAT Concatenate a list of tables
%   T = TBL_CONCAT(TL) reads a list TSV files TL and returns a structure
%   array T that is a concatenation of all the tables. 

tbl_list = parse_grp(tbl_list);
ntbl = length(tbl_list);
tbl = parse_record(tbl_list{1}, 'detect_numeric', false);
fn = fieldnames(tbl);
miss_val = {'-666'};

for ii=2:ntbl
    new_tbl = parse_record(tbl_list{ii},  'detect_numeric', false);
    new_fn = fieldnames(new_tbl);
    all_fn = union(fn, new_fn, 'stable');
    
    miss_old = setdiff(all_fn, fieldnames(tbl));
    fill_old = miss_val(ones(length(miss_old), 1));
    
    miss_new = setdiff(all_fn, new_fn);
    fill_new = miss_val(ones(length(miss_new), 1));
    
    tbl = setarrayfield(tbl, [], miss_old, fill_old{:});
    new_tbl = setarrayfield(new_tbl, [], miss_new, fill_new{:});
    tbl = [tbl; new_tbl];    
end
end
