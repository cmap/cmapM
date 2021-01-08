function ie = isexpressed(gene_list, cell_list)
% ISEXPRESSED Check baseline gene expression in given cell line(s).
% IE = ISEXPRESSED(GENE_LIST, CELL_LIST)

ng = length(gene_list);
nc = length(cell_list);
iemat = -666*ones(ng, nc);
res = mongo_info('gene_info', gene_list,...
                 'query_field', 'pr_gene_symbol',...
                 'fields', [{'pr_gene_symbol'};...
                             strcat('is_expressed.', cell_list(:))]);

for ii=1:ng
    if ~isempty(res(ii).is_expressed)
        this_cidx = res(ii).is_expressed.iskey(cell_list);
        iemat(ii, this_cidx) = res(ii).is_expressed(cell_list(this_cidx));
    end
end

ie = mkgctstruct(iemat, 'rid', gene_list, 'cid', cell_list);

end