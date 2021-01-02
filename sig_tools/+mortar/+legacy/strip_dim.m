function [p, f, e, fn] = strip_dim(s)
% STRIP_DIM Remove dimension information from a filename.
%   [P, F, E, FN] = STRIP_DIM(S)
    [p,f,e] = fileparts(s);
    f = regexprep(f, '_n[0-9]*x[0-9]*$','');
    fn = fullfile(p, [f, e]);
end