function ds = ds_transpose(ds)
% DS_TRANSPOSE Transpose a GCT structure
% OUT_DS = DS_TRANSPOSE(IN_DS) transpose the rosw and columns of the
% underlying matrix and metadata fields of a GCT structure IN_DS

ds = transpose_gct(ds);

end