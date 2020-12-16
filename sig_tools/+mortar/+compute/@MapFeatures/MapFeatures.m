classdef MapFeatures
% Methods that map between gene ids
    properties(Constant=true)
    end

    methods(Static=true)
        
        % Convert affx ids to gene-ids
        [out_gmt, unmapped_gmt] = mapAffxToGeneId(in_gmt, l1kspace);
        
        % Convert affx ids to L1k ids
        [out_gmt, unmapped_gmt] = mapAffxToL1000(in_gset, l1kspace);
        
        [out_gmt, unmapped_gmt] = mapAffxToGeneSymbol(in_gset);
        
        % Convert gene symbols to gene-ids
        [out_gmt, unmapped_gmt] = mapGeneSymbolToGeneId(in_gmt, l1k_space);
        
        % Convert gene symbols to L1k ids
        [out_gmt, unmapped_gmt] = mapGeneSymbolToL1000(in_gmt, l1k_space);
        
        % Convert gene-ids to L1k ids
        [out_gmt, unmapped_gmt] = mapGeneIdToL1000(in_gmt, l1k_space);
        
        % Convert any supported id to L1k ids
        [out_gmt, unmapped_gmt] = mapAnyIdToL1000(in_gmt, input_id, l1k_space);
        
        % Convert any supported id to L1k ids
        [out_gmt, unmapped_gmt] = mapAnyIdToGeneId(in_gmt, input_id, l1k_space);
        
        % Use specified feature platfrom to perform gene mapping
        [out_gmt, unmapped_gmt] = mapGeneWithChip(chip_platform, chip_space, in_gmt, from_id, to_id);
        
        % Map gene names using a supplied chip file
        [out_gmt, unmapped_gmt] = mapGeneWithChipFile(chip_file, in_gmt, from_id, to_id);

        % filter sets by size
        [out_gmt, filt_gmt] = filterSetsBySize(in_gmt, min_size, max_size);
        
        % Convert Ensembl ids
        out = mapEnsemblToL1000(ds);
        % Convert dataset from Affymetrix U133A to Gene-ids
        aig_ds = convertL1000Dataset(ds, chip_info);
        
        % PR-500 utils
        % Map CMap cell names to PR-500 feature-ids
        [out_gmt, unmapped_gmt] = mapCellNameToPR500(in_gmt);
        % Map PR-500 feature-ids to CMap cell names
        [out_gmt, unmapped_gmt] = mapPR500ToCellName(in_gset);
        
        
    end % Static methods block
       
end
