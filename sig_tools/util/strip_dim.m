function [p, f, e, fn] = strip_dim(s)
% STRIP_DIM Remove dimension information from a filename.
%   [P, F, E, FN] = STRIP_DIM(S)
    [p,f,e] = fileparts(s);
    f = strip_dimlabel(f);
    fn = fullfile(p, [f, e]);
end