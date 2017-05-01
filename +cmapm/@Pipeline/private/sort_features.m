function ds = sort_features(ds, varargin)
% SORT_FEATURES Sort dataset features.
% SRTDS = SORT_FEATURES(DS) where DS is a dataset with the following row
% descriptor fields:
% {'pr_is_lmark' ,'pr_analyte_num', 'pr_gene_symbol'}

key = {'pr_is_lmark' ,'pr_analyte_num', 'pr_gene_symbol'};
sort_order = [-1, 1, 1];

key2 = {'pr_analyte_num', 'pr_gene_symbol'};
sort_order2 = [ 1, 1];

key3 = {'pr_gene_symbol'};
sort_order3 = 1;

if all(ds.rdict.isKey(key))
    keyidx = cell2mat(ds.rdict.values(key));
    [~, ridx] = sortrows(ds.rdesc, keyidx.*sort_order);
    ds = gctextract_tool(ds, 'rid', ds.rid(ridx));
elseif all(ds.rdict.isKey(key2))
    keyidx = cell2mat(ds.rdict.values(key2));
    [~, ridx] = sortrows(ds.rdesc, keyidx.*sort_order2);
    ds = gctextract_tool(ds, 'rid', ds.rid(ridx));
elseif all(ds.rdict.isKey(key3))
    keyidx = cell2mat(ds.rdict.values(key3));
    [~, ridx] = sortrows(ds.rdesc, keyidx.*sort_order3);
    ds = gctextract_tool(ds, 'rid', ds.rid(ridx));
else
    fprintf('Not sorting features\n');
end

end
