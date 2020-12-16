function mkparam(fname, name, param)
% MKPARAM Create parameter file.
%   MKPARAM(FNAME, NAME, PARAM) NAME
fid = fopen(fname, 'wt');
print_args(name, fid, param)
fclose(fid);
end