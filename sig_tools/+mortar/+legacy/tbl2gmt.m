function gmt = tbl2gmt(tbl, varargin)
% table with the following fields: name, desc, gene_symbol
% genesets will be grouped by name
[cn, nl] = getcls(tbl.name);
n = length(cn);
hd = cell(n,1); 
desc = cell(n,1); 
gset = cell(n,1);
len = num2cell(zeros(n,1));
gmt =  struct('head', hd, 'desc', desc, 'entry', gset, 'len', len);
for ii=1:n
    gmt(ii).head = cn{ii}; 
    idx = find(nl==ii); 
    gmt(ii).desc = tbl.desc{idx(1)}; 
    gmt(ii).entry = tbl.gene_symbol(idx);
    gmt(ii).len = length(idx);
end
end