function [out_gmt, filt_gmt] = filterSetsBySize(in_gmt, min_size, max_size)
% filterSetsBySize Filter genesets by set size
%   [OUT_GMT, FILT_GMT] = filterSetsBySize(in_gmt, min_size, max_size)
out_gmt = parse_geneset(in_gmt);
sz = [out_gmt.len]';
keep = sz>=min_size & sz <=max_size;
filt_gmt = out_gmt(~keep);
out_gmt = out_gmt(keep);

end