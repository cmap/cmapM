function fp = add_dim(s, nr, nc)
% ADD_DIM Add dimension information to a filename.
%   FN = ADD_DIM(F, NR, NC)
    [p,f,e] = fileparts(s);
    fn = sprintf('%s_n%dx%d%s', f, nc, nr, e);
    fp = fullfile(p, fn);
end