function all_maps = assignReplicateGroups(all_maps, split_by, group_by, group_field)
% assignReplicateGroups Add a grouping field to indicate replicates in a plate map
% new_maps = assignReplicateGroups(all_maps, split_by, group_by, group_field)

map_group = {all_maps.(split_by)}';
[cn, nl] = getcls(map_group);
nmap = length(cn);

for ii=1:nmap
    this = nl == ii;
    this_map = all_maps(this);
                        
    gpv = get_groupvar(this_map, [], group_by);
    [dup, idup, gdup, repnum] = duplicates(gpv);
    replicate_num = ones(nnz(this), 1);
    replicate_num(idup) = repnum;
    group_by_id = upper(strrep(paste([gpv, num2cellstr(replicate_num)], ':'), ' ', ''));
    all_maps = setarrayfield(all_maps, this, group_field, group_by_id);
        
end

end