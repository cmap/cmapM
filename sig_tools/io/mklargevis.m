function mklargevis(m, fname)
% Save feature vectore in Large vis format
[nrow, ncol] = size(m);
fid = fopen(fname, 'wt');
fprintf(fid, '%d\t%d\n', nrow, ncol);
fclose(fid);
dlmwrite(fname, m, '-append', 'delimiter', '\t')

end