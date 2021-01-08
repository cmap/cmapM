function [out_gmt, unmapped_gmt] = mapPR500ToCellName(in_gset)
% mapPR500ToCellName Map PR500 feature ids to CMap cell names.
% [OUT_GMT, UNMAPPED_GMT] = mapPR500ToCellName(IN_GMT) Converts PR500
% feature identifiers in the set IN_GMT to cell names (standardized CMap
% inames). IN_GMT is a PARSE_GENESET compatible data structure or file with
% one or more sets comprising of feature-ids. OUT_GMT is a GMT structure
% containing the mapped set(s) comprised of cell names. UNMAPPED_GMT is a
% GMT structure with feature-ids that were not mapped.

in_gset = parse_geneset(in_gset);

[out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneWithChip(...
                            'pr500_cs5', 'all', in_gset,...
                            'feature_id', 'cell_iname');

end