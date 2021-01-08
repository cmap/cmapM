function [left_map, right_map] = split_map(map_file)

full_map = parse_record(map_file);
[wn, word] = get_wellinfo({full_map.rna_well}');
is_left_map = word <=192;
is_right_map = word >192;

left_map = full_map(is_left_map);
right_map = full_map(is_right_map);

end