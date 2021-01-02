function [out_gmt, unmapped_gmt] = mapCellNameToPR500(in_gset)
% mapCellNameToPR500 Map CMap compatible cell name to PR500 feature ids.
% [OUT_GMT, UNMAPPED_GMT] = mapCellNameToPR500(IN_GMT) Converts cell names
% in the set IN_GMT to PR500 feature identifiers. IN_GMT is
% a PARSE_GENESET compatible data structure or file with one or more
% sets comprising of cell names. OUT_GMT is a GMT structure
% containing the mapped set(s) comprised of PR500 feature-ids.
% UNMAPPED_GMT is a GMT structure with cell names that were not mapped.

in_gset = parse_geneset(in_gset);

[out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneWithChip(...
                            'pr500_cs5', 'all', in_gset,...
                            'cell_iname', 'feature_id');

end
