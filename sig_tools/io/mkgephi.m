function mkgephi(ofname, ds)
if ~isempty(ds.cdesc) && ds.cdict.isKey('pert_iname')
    cid = ds_get_meta(ds, 'column', 'pert_iname');
else
    cid = ds.cid;
end
if ~isempty(ds.rdesc) && ds.rdict.isKey('pert_iname')
    rid = ds_get_meta(ds, 'row', 'pert_iname');
else
    rid = ds.rid;
end
[nr,nc] = size(ds.mat);
fid = fopen(ofname, 'wt');
fprintf(fid, ';');
print_dlm_line(cid,'dlm',';','fid',fid)
for ii=1:nr
print_dlm_line([rid(ii), num2cell(ds.mat(ii,:))], 'dlm',';','fid',fid)
end
fclose(fid);

end