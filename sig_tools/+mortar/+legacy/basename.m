function bn = basename(p)

if ischar(p)
    p = {p};
end
np = length(p);
bn = cell(np, 1);
for ii=1:np
    [~, f, e] = fileparts(p{ii});
    bn{ii} = [f,e];
end
    
end