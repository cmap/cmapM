
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function [c, ia, ib] =  map_ord(a,b)

na = length(a);
nb = length(b);
ua = unique(a);
ub = unique(b);

if isequal(na,length(ua)) && isequal(nb, length(ub))
    [c, ia, ib ] = intersect_ord(a,b);
else
    hm = containers.Map(a,1:length(a));
    ctr=0;
    for ii=1:nb                
        if isKey(hm, b{ii})
            val = hm(b{ii});
            ctr = ctr+1;
            c{ctr,1} = b{ii};
            ia(ctr) = val;
            ib(ctr) = ii;
        end
    end
end
