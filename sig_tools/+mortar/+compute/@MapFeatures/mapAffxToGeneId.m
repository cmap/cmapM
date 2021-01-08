function [out_gmt, unmapped_gmt] = mapAffxToGeneId(in_gset, l1k_space)
% mapAffxToGeneId Map Affymetrix U133 probeset-ids to Entrez Gene-ids
% [OUT_GMT, UNMAPPED_GMT] = mapAffxToGeneId(IN_GMT) Converts Affymetrix
% probeset-ids in the geneset IN_GMT to Entrez gene identifiers. IN_GMT is
% a PARSE_GENESET compatible data structure or file with one or more
% genesets comprising of Entrez gene-ids. OUT_GMT is a GMT structure
% containing the mapped geneset(s) comprised of Entrez gene-ids.
% UNMAPPED_GMT is a GMT structure with probeset-ids that were not mapped.

in_gset = parse_geneset(in_gset);

[out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneWithChip('affx_u133', 'l1000', in_gset,...
                            'pr_id', 'pr_gene_id');

end
