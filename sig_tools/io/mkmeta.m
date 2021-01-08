function mkmeta(ofname, ds, dim, varargin)

switch(lower(dim))
    case 'row'
        meta = [ds.rid, ds.rdesc];
        hd = [{'rid'}; ds.rhd];
    case 'column'
        meta = [ds.cid, ds.cdesc];
        hd = [{'cid'}; ds.chd];
    otherwise
        error('dim must be row or column')
end
       
mktbl(ofname, meta, 'header', hd)

end