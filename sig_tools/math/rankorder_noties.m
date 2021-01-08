function [m, ridx, sidx] = rankorder_noties(m)
[nr, nc]= size(m);
if nr==1 && nc>1 
    m=m(:);
end
ord = (1:nr)';
[~, ridx] = sort(m, 1);
sidx = bsxfun(@plus, ridx, (nr*(0:nc-1)));
m(sidx) = repmat(ord, 1, nc);
end
