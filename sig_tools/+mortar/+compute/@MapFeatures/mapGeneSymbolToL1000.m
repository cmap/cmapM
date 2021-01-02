function [out_gmt, unmapped_gid] = mapGeneSymbolToL1000(in_gset, l1k_space)
% mapGeneSymbolToL1000 Map gene symbols to L1000 ids
% [OUT_GMT, UNMAPPED_GMT] = mapGeneSymbolToL1000(IN_GMT) Converts gene
% symbols in the geneset IN_GMT to L1000 identifiers. IN_GMT is
% a PARSE_GENESET compatible data structure or file with one or more
% genesets comprising of gene symbols. OUT_GMT is a GMT structure
% containing the mapped geneset(s) comprised of L1000 ids.
% UNMAPPED_GMT is a GMT structure with gene symbols that were not mapped.

in_gset = parse_geneset(in_gset);
% map symbols to gene-ids
[gid_gset, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneSymbolToGeneId(in_gset, l1k_space);
% map gene-ids to l1000
[out_gmt, unmapped_gid] = mortar.compute.MapFeatures.mapGeneIdToL1000(gid_gset, l1k_space);

end
