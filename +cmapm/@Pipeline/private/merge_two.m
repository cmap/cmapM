function combods = merge_two(ds1, ds2, isverbose)
% MERGE_TWO Combine two datasets
% COMBODS = MERGE_TWO(DS1, DS2)

if isvarexist('isverbose')
    isverbose = logical(isverbose);
else
    isverbose = true;
end

combods = mkgctstruct();
[nr1, nc1] = size(ds1.mat);
[nr2, nc2] = size(ds2.mat);
cmncid = intersect_ord(ds2.cid, ds1.cid);
cmnrid = intersect_ord(ds2.rid, ds1.rid);
nc = length(cmncid);
nr = length(cmnrid);

if isempty(cmncid) && isequal(nr, nr1)
    % cids are disjoint and rids intersect : append columns
    dbg(isverbose, 'Appending cols')
    combods.cid = [ds1.cid; ds2.cid];
    combods.rid = cmnrid;
    % row annotation
    combods.rhd = ds1.rhd;
    combods.rdesc = ds1.rdesc;
    
    % data matrix
    [~, ridx1] = intersect_ord(ds1.rid, combods.rid);
    [~, ridx2] = intersect_ord(ds2.rid, combods.rid);
    combods.mat = [ds1.mat(ridx1,:), ds2.mat(ridx2,:)];
    
    % column annotation
    combods.chd = union(ds1.chd, ds2.chd);
    if ~isempty(combods.chd)
        [~, chdx1, cmnchdx1] = intersect_ord(ds1.chd, combods.chd);
        [~, chdx2, cmnchdx2] = intersect_ord(ds2.chd, combods.chd);
        combods.cdesc = cell(nc1+nc2, length(combods.chd));
        combods.cdesc(:) = {-666};
        if ~isempty(chdx1)
            combods.cdesc(1:nc1, cmnchdx1) = ds1.cdesc(:, chdx1);
        end
        if ~isempty(chdx2)
            combods.cdesc(nc1+(1:nc2), cmnchdx2) = ds2.cdesc(:, chdx2);
        end
        % fix multi-class columns
        combods.cdesc = fix_annotation_class(combods.cdesc);
    end
elseif isempty(cmnrid) && isequal(nc, nc1)
    % rids are disjoint and cids intersect : append rows
    dbg(isverbose, 'Appending rows')
    combods.rid = [ds1.rid; ds2.rid];
    combods.cid = cmncid;
    %column annotation
    combods.chd = ds1.chd;
    combods.cdesc = ds1.cdesc;
    
    %data matrix
    [~, cidx1] = intersect_ord(ds1.cid, combods.cid);
    [~, cidx2] = intersect_ord(ds2.cid, combods.cid);
    combods.mat = [ds1.mat(:, cidx1); ds2.mat(:, cidx2)];
    
    %row annotation
    combods.rhd = union(ds1.rhd, ds2.rhd);
    if ~isempty(combods.rhd)
        [~, rhdx1, cmnrhdx1] = intersect_ord(ds1.rhd, combods.rhd);
        [~, rhdx2, cmnrhdx2] = intersect_ord(ds2.rhd, combods.rhd);
        combods.rdesc = cell(nr1+nr2, length(combods.rhd));
        combods.rdesc(:) = {-666};
        if ~isempty(rhdx1)
            combods.rdesc(1:nr1, cmnrhdx1) = ds1.rdesc(:, rhdx1);
        end
        if ~isempty(rhdx2)
            combods.rdesc(nr1+(1:nr2), cmnrhdx2) = ds2.rdesc(:, rhdx2);
        end
        % fix multi-class columns
        combods.rdesc = fix_annotation_class(combods.rdesc);
    end
else
    % ambiguous / name collisions
    if isequal(nr, nr1)
        dbg(1, 'CID collisions')
        disp(cmncid)
    elseif isequal(nc, nc1)
        dbg(1, 'RID collisions')
        disp(cmnrid)
    else
        dbg(1, 'CID and RID collisions')
        disp(cmncid)
        disp(cmnrid)
    end
    warning('Invalid inputs, cannot merge')
    % simply return ds1
    combods = ds1;
end
% update dict
combods.cdict = list2dict(combods.chd);
combods.rdict = list2dict(combods.rhd);
end