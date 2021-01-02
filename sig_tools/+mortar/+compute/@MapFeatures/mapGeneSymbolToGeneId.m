function [out_gmt, unmapped_gmt] = mapGeneSymbolToGeneId(in_gset, l1k_space)
% mapGeneSymbolToGeneId Map gene symbols to Entrez gene-ids
% [OUT_GMT, UNMAPPED_GMT] = mapGeneSymbolToGeneId(IN_GMT) Converts gene
% symbols in the geneset IN_GMT to Entrez gene identifiers. IN_GMT is
% a PARSE_GENESET compatible data structure or file with one or more
% genesets comprising of gene symbols. OUT_GMT is a GMT structure
% containing the mapped geneset(s) comprised of Entrez gene-ids.
% UNMAPPED_GMT is a GMT structure with gene symbols that were not mapped.

in_gset = parse_geneset(in_gset);
[out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneWithChip('l1000', l1k_space, in_gset,...
                            'pr_gene_symbol', 'pr_gene_id');

end
