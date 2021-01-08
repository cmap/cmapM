function [out_gmt, unmapped_gid] = mapAffxToL1000(in_gset, l1k_space)
% mapAffxToL1000 Map Affymetrix U133 probeset-ids to L1000 compatible ids
% [OUT_GMT, UNMAPPED_GMT] = mapAffxToL1000(IN_GMT) Converts Affymetrix U133
% probeset-ids in the geneset IN_GMT to L1000 compatible gene identifiers.
% IN_GMT is a PARSE_GENESET compatible data structure or file with one or
% more genesets comprising of Affymetrix U133 ids. OUT_GMT is a GMT
% structure containing the mapped geneset(s) comprised of L1000 ids.
% UNMAPPED_GMT is a GMT structure with probeset-ids that were not mapped.

in_gset = parse_geneset(in_gset);
% map affx to gene-ids
[gid_gset, unmapped_gmt] = mortar.compute.MapFeatures.mapAffxToGeneId(in_gset);

% map gene-ids to l1000
[out_gmt, unmapped_gid] = mortar.compute.MapFeatures.mapGeneIdToL1000(gid_gset, l1k_space);

end
