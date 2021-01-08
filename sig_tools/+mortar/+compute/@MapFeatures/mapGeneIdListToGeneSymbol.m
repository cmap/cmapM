function [geneSym, isfound] = mapGeneIdListToGeneSymbol(gene_id, alt_name)
% mapGeneIdToGeneSymbol Look up CMap compatible gene symbols for a list of Entrez gene-ids
% [geneSym, isfound] = mapGeneIdToGeneSymbol(gene_id, alt_name)

n = length(gene_id);
nalt = length(alt_name);
assert(isequal(n, nalt), 'Lengths of gene_id and alt_name should match')
ez_chip = mortar.common.Chip.get_chip('entrez','all');
% sync with CMap names
sym_lut = mortar.containers.Dict({ez_chip.pr_gene_id}', {ez_chip.pr_gene_symbol}');
if all(isnumeric_type(gene_id))
    gene_id = num2cellstr(gene_id);
end
isfound = sym_lut.isKey(gene_id);
%%
geneSym = cell(n, 1);
geneSym(isfound) = sym_lut(gene_id(isfound));
geneSym(~isfound) = alt_name(~isfound);
end