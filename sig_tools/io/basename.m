function [bn, bf, be] = basename(p)
% BASENAME strip directory from filenames
%   B = BASENAME(P) P can be a string or cell array of strings.

if ischar(p)
    p = {p};
end
np = length(p);
bn = cell(np, 1);
bf = cell(np, 1);
be = cell(np, 1);
for ii=1:np
    [~, f, e] = fileparts(p{ii});
    bn{ii} = [f,e];
    bf{ii} = f;
    be{ii} = e;
end
    
end