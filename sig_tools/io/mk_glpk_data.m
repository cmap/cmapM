function mk_glpk_data(ds, outfile)

ds = parse_gctx(ds);
assert(isds(ds));

fid = fopen(outfile, 'wt');

% row id
fprintf(fid, 'set RID:=');
fprintf(fid, '%s ', ds.rid{:});
fprintf(fid, ';\n');

% col id
fprintf(fid, 'set CID:=');
fprintf(fid, '%s ', ds.cid{:});
fprintf(fid, ';\n');

% data matrix
fprintf(fid, 'param MATRIX:');
fprintf(fid, '%s ', ds.cid{:});
fprintf(fid, ':=\n');
[nrow, ncol] = size(ds.mat);
for ii=1:nrow
    fprintf(fid, '%s ', ds.rid{ii});
    fprintf(fid, '%g ', ds.mat(ii, :));
    fprintf(fid, '\n');
end
fprintf(fid, ';\n');

fclose(fid);
end