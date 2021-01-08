function [out_gmt, unmapped_gmt] = mapGeneIdToL1000(in_gset, l1k_space)
% mapGeneIdToL1000 Map Entrez gene-ids to L1000 compatible ids
% [OUT_GMT, UNMAPPED] = mapGeneIdToL1000(IN_GMT) Converts Entrez gene-ids
% in the geneset IN_GMT to L1000 compatible identifiers.
% (currently the landmarks + best inferred Affymetrix probeset ids). IN_GMT
% is a PARSE_GENESET compatible data structure or file with one or more 
% genesets comprising of Entrez gene-ids. OUT_GMT is a GMT 
% structure containing the mapped geneset(s) comprised of L1000 ids.
% UNMAPPED is a GMT structure with gene-ids that were not mapped.

in_gset = parse_geneset(in_gset);
% Map to best inferred genes + LM
[out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneWithChip(...
                            'l1000', l1k_space, in_gset,...
                            'pr_gene_id', 'pr_id');

end

