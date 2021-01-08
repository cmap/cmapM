function [left_map, right_map] = split_map_to_unilr(map_file)
% SPLIT_MAP_TO_UNILR Split a full mapfile to UNI Left and Right halves.
%   [left_map, right_map] = split_map_to_unilr(map_file)
%
%   Example:
%   [left_map, right_map] = split_map('/path/to/full_map')
%   mktbl('left.map', left_map)
%   mktbl('right.map', right_map)

full_map = parse_record(map_file);
[wn, word] = get_wellinfo({full_map.rna_well}');
is_left_map = word <=192;
is_right_map = word >192;

left_map = full_map(is_left_map);
right_map = full_map(is_right_map);

end