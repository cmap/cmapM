function mkdsbin(out_file, ds)
% mkdsbin Write binary file corresponding to a 2d-data matrix
%   MKDSBIN(OUT_FILE, DS) writes Dataset DS to OUT_FILE
%  Binary file format:
%  Header: NROW, NCOL uint64
%  Matrix elements as single precision values
dim = size(ds.mat);
fid = fopen(out_file, 'wb');
fwrite(fid, dim, 'uint64');
fwrite(fid, ds.mat, 'single');
fclose(fid);

end