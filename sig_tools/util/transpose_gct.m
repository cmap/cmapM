% TRANSPOSE_GCT Tranpose a GCT structure
%   DS = transpose_gct(DS)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function ds = transpose_gct(ds)

if isstruct(ds)
    ds.mat = ds.mat';
    [ds.rid, ds.cid] = swap(ds.rid, ds.cid);
    [ds.rhd, ds.chd] = swap(ds.rhd, ds.chd);
    [ds.rdesc, ds.cdesc] = swap(ds.rdesc, ds.cdesc);
    ds.rdict = list2dict(ds.rhd);
    ds.cdict = list2dict(ds.chd);
end
end

function [a,b] =swap(a,b)
tmp = a;
a = b;
b = tmp;
end