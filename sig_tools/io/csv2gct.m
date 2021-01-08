function ds = csv2gct(csvfile)
% CSV2GCT Convert CSV file to GCT structure
% DS = CSV2GCT(CSVFILE)

csvtbl = readtable(csvfile, 'ReadRowNames', true, 'TreatAsEmpty', 'NA');
mat = table2array(csvtbl);
cid = csvtbl.Properties.VariableNames;
rid = csvtbl.Properties.RowNames;
ds = mkgctstruct(mat, 'rid', rid, 'cid', cid);

end