function rpt = get_hit_pairs(ds, th)
% GET_HIT_PAIRS 
tokeep = abs(ds.mat)>=th;

[ir, ic] = find(tokeep);
val = num2cell(ds.mat(tokeep));
colmeta=gctmeta(ds);
rowmeta=gctmeta(ds,'row');
hd = [strcat(fieldnames(colmeta),'_col'); strcat(fieldnames(rowmeta),'_row'); {'score'}];
desc = [struct2cell(colmeta(ic))', struct2cell(rowmeta(ir))', val];

rpt = cell2struct(desc, hd, 2);
% hit frequencies of row and column ids
[rgp, ridx]=getcls(ir);
% hit count for each row expressed as a percentage of total columns
rf = 100*accumarray(ridx, ones(size(ridx)))/size(ds.mat,2);
rf_lut = mortar.containers.Dict(ds.rid(rgp), rf);

[cgp, cidx]=getcls(ic);
% hit count for each column expressed as a percentage of total rows
cf = 100*accumarray(cidx, ones(size(cidx)))/size(ds.mat,1);
cf_lut = mortar.containers.Dict(ds.cid(cgp), cf);

rf_cell = num2cell(rf_lut({rpt.rid_row}));
cf_cell = num2cell(cf_lut({rpt.cid_col}));

[rpt.rid_freq]= rf_cell{:};
[rpt.cid_freq]= cf_cell{:};

end