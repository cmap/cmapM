function [filt_set, excluded_set] = setfilter(set, keep_list, min_size, max_size)
% SETFILTER Filter set members
% FS = SETFILTER(S, L, MINSZ, MAXSZ) returns sets FS which are a subset of
% sets S and whose members belong to list L and have a set size of at least
% MINSZ and not more than MAXSZ. If L is empty all members are retained and
% if MINSIZ is <1 all set sizes are retained.
% 
% [FS, EXS] = SETFILTER(S, L, MINSZ, MAXSZ) returns sets that were excluded

tbl = gmt2tbl(set);
if ~isempty(tbl)
    if isempty(keep_list)
        keep_list_lut = mortar.containers.Dict(unique({tbl.member_id}'));
    else
        keep_list_lut = mortar.containers.Dict(keep_list);        
    end    
    to_keep = keep_list_lut.isKey({tbl.member_id}');
    tbl = tbl(to_keep);
    
    filt_set = tbl2gmt(tbl);
    if ~isempty(filt_set)
        keep_set = [filt_set.len]'>=min_size & [filt_set.len]'<=max_size;
        excluded_set = filt_set(~keep_set);
        filt_set = filt_set(keep_set);
    else
        excluded_set = [];
    end
else
    filt_set = mkgmtstruct({}, {}, {});
    excluded_set = mkgmtstruct({}, {}, {});
end

end