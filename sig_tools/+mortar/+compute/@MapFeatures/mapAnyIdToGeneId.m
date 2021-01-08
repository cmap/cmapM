function [out_gmt, unmapped_gmt] = mapAnyIdToGeneId(in_gset, input_id, l1k_space)
% mapAnyIdToL1000 Map Entrez gene-ids to L1000 compatible ids
% [OUT_GMT, UNMAPPED] = mapAnyIdToL1000(IN_GMT, INPUT_ID) Converts any supported ids
% in the geneset IN_GMT to L1000 compatible identifiers.
% (currently the landmarks + best inferred Affymetrix probeset ids). IN_GMT
% is a PARSE_GENESET compatible data structure or file with one or more 
% genesets comprising of valid ids. OUT_GMT is a GMT 
% structure containing the mapped geneset(s) comprised of L1000 ids.
% UNMAPPED is a GMT structure with ids that were not mapped.

valid_ids = {'gene_symbol', 'gene_id', 'affx'};
in_gset = parse_geneset(in_gset);
switch lower(input_id)
    case 'gene_symbol'
        [out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneSymbolToGeneId(in_gset, l1k_space);
    case 'gene_id'
        [out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneWithChip('l1000', l1k_space, in_gset,...
                            'pr_gene_id', 'pr_gene_id');
        %[out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapGeneIdToL1000(in_gset, l1k_space);
    case 'affx'
        [out_gmt, unmapped_gmt] = mortar.compute.MapFeatures.mapAffxToGeneId(in_gset, l1k_space);
    otherwise       
        error('Unsupported id : %s. Expected one of %s',...
            input_id, print_dlm_line(valid_ids, 'dlm', ','));
end

end
