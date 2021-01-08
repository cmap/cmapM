function split_table_to_file(all_maps, split_by, out_path, ext)

map_group = {all_maps.(split_by)}';
[cn, nl] = getcls(map_group);
ngroup = length(cn);
mkdirnotexist(out_path);

for ii=1:ngroup
    this = nl == ii;
    this_out = fullfile(out_path, sprintf('%s.%s', cn{ii}, ext));
    jmktbl(this_out, all_maps(this));        
end


end